#!/bin/bash
# Provision standard settings for a new lucos repo:
#   - LUCOS_CI_APP_ID and LUCOS_CI_PRIVATE_KEY repository secrets
#   - fork-pr-contributor-approval policy (first_time_contributors_new_to_github)
#
# Usage: provision-repo-ci-secrets.sh <repo-name>
# Example: provision-repo-ci-secrets.sh lucos_dns_secondary
#
# Requires:
#   - ~/sandboxes/lucos_agent/.env with LUCOS_CI_APP_ID and LUCOS_CI_PEM
#   - ~/sandboxes/lucos_agent/gh-as-agent (lucos-system-administrator app)
#   - python3 with PyNaCl (pip3 install PyNaCl)

set -euo pipefail

REPO="${1:?Usage: $0 <repo-name>}"
LUCOS_AGENT_ENV="$HOME/sandboxes/lucos_agent/.env"
GH_AS_AGENT="$HOME/sandboxes/lucos_agent/gh-as-agent"

echo "Provisioning CI secrets for lucas42/${REPO}..."

# --- Step 1: Extract values from lucos_agent/.env ---
# APP_ID is a simple integer — single-line safe
APP_ID=$(grep '^LUCOS_CI_APP_ID=' "$LUCOS_AGENT_ENV" | cut -d'"' -f2)
if [ -z "$APP_ID" ]; then
    echo "ERROR: LUCOS_CI_APP_ID not found or empty in $LUCOS_AGENT_ENV" >&2
    exit 1
fi
echo "APP_ID: $APP_ID"

# PEM is multiline — MUST use Python, not grep|cut (cut returns only the first line)
PEM=$(python3 - <<'PYEOF'
import re, sys

env_path = __import__('os').path.expanduser('~/sandboxes/lucos_agent/.env')
with open(env_path, 'r') as f:
    content = f.read()

match = re.search(r'LUCOS_CI_PEM="((?:[^"\\]|\\.)*)"', content, re.DOTALL)
if not match:
    print("ERROR: LUCOS_CI_PEM not found in .env", file=sys.stderr)
    sys.exit(1)

pem = match.group(1)
# Sanity check: must be a complete PEM, not just the header
if pem.count('\n') < 10:
    print(f"ERROR: PEM looks truncated ({len(pem)} chars, {pem.count(chr(10))} newlines). Expected 20+ newlines.", file=sys.stderr)
    sys.exit(1)

print(pem, end='')
PYEOF
)

PEM_LINES=$(echo "$PEM" | wc -l)
echo "PEM: ${#PEM} chars, ${PEM_LINES} lines — looks complete"

# --- Step 2: Get repo's public key for libsodium encryption ---
PUB_KEY_RESPONSE=$("$GH_AS_AGENT" --app lucos-system-administrator \
    "repos/lucas42/${REPO}/actions/secrets/public-key")
PUB_KEY=$(echo "$PUB_KEY_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['key'])")
KEY_ID=$(echo "$PUB_KEY_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['key_id'])")
echo "Repo public key_id: $KEY_ID"

# --- Step 3: Encrypt and set LUCOS_CI_PRIVATE_KEY ---
ENCRYPTED_PEM=$(python3 - <<PYEOF
import base64, json, sys
from nacl.encoding import Base64Encoder
from nacl.public import PublicKey, SealedBox

pem = """${PEM}"""
pub_key = PublicKey("${PUB_KEY}", encoder=Base64Encoder)
encrypted = SealedBox(pub_key).encrypt(pem.encode('utf-8'), encoder=Base64Encoder)
print(encrypted.decode())
PYEOF
)

python3 - <<PYEOF | "$GH_AS_AGENT" --app lucos-system-administrator \
    "repos/lucas42/${REPO}/actions/secrets/LUCOS_CI_PRIVATE_KEY" \
    --method PUT --input /dev/stdin
import json
print(json.dumps({"encrypted_value": "${ENCRYPTED_PEM}", "key_id": "${KEY_ID}"}))
PYEOF
echo "LUCOS_CI_PRIVATE_KEY set."

# --- Step 4: Encrypt and set LUCOS_CI_APP_ID ---
ENCRYPTED_APP_ID=$(python3 - <<PYEOF
import base64, json
from nacl.encoding import Base64Encoder
from nacl.public import PublicKey, SealedBox

pub_key = PublicKey("${PUB_KEY}", encoder=Base64Encoder)
encrypted = SealedBox(pub_key).encrypt("${APP_ID}".encode('utf-8'), encoder=Base64Encoder)
print(encrypted.decode())
PYEOF
)

python3 - <<PYEOF | "$GH_AS_AGENT" --app lucos-system-administrator \
    "repos/lucas42/${REPO}/actions/secrets/LUCOS_CI_APP_ID" \
    --method PUT --input /dev/stdin
import json
print(json.dumps({"encrypted_value": "${ENCRYPTED_APP_ID}", "key_id": "${KEY_ID}"}))
PYEOF
echo "LUCOS_CI_APP_ID set."

# --- Step 5: Set fork-PR contributor approval policy ---
# New repos default to 'first_time_contributors'; lucos convention requires
# 'first_time_contributors_new_to_github' so agent bot workflows run without
# a manual "Approve and run" gate.
"$GH_AS_AGENT" --app lucos-system-administrator \
    "repos/lucas42/${REPO}/actions/permissions/fork-pr-contributor-approval" \
    --method PUT \
    -f approval_policy=first_time_contributors_new_to_github > /dev/null
echo "fork-pr-contributor-approval set to first_time_contributors_new_to_github."

# --- Step 6: Set LUCOS_CI_APP_ID and LUCOS_CI_PRIVATE_KEY in Dependabot secrets ---
# GitHub only exposes Dependabot secrets (not Actions secrets) when a Dependabot
# PR triggers a workflow. Without them in the Dependabot store, the reusable
# dependabot-auto-merge workflow falls back to GITHUB_TOKEN, breaking auto-merge.
DEP_KEY_RESPONSE=$("$GH_AS_AGENT" --app lucos-system-administrator \
    "repos/lucas42/${REPO}/dependabot/secrets/public-key")
DEP_PUB_KEY=$(echo "$DEP_KEY_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['key'])")
DEP_KEY_ID=$(echo "$DEP_KEY_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['key_id'])")
echo "Dependabot public key_id: $DEP_KEY_ID"

# Encrypt APP_ID for Dependabot
DEP_ENCRYPTED_APP_ID=$(python3 - <<PYEOF
from nacl.encoding import Base64Encoder
from nacl.public import PublicKey, SealedBox
pub_key = PublicKey("${DEP_PUB_KEY}", encoder=Base64Encoder)
encrypted = SealedBox(pub_key).encrypt("${APP_ID}".encode('utf-8'), encoder=Base64Encoder)
print(encrypted.decode())
PYEOF
)
python3 -c "import json; print(json.dumps({'encrypted_value': '${DEP_ENCRYPTED_APP_ID}', 'key_id': '${DEP_KEY_ID}'}))" | \
    "$GH_AS_AGENT" --app lucos-system-administrator \
    "repos/lucas42/${REPO}/dependabot/secrets/LUCOS_CI_APP_ID" \
    --method PUT --input /dev/stdin > /dev/null
echo "LUCOS_CI_APP_ID set in Dependabot secrets."

# Encrypt PEM for Dependabot (must use temp-file Python — heredoc shell expansion breaks the regex)
DEP_SCRIPT=$(mktemp /tmp/dep-enc-XXXXXX.py)
cat > "$DEP_SCRIPT" << PYEOF
import re, json, os
from nacl.encoding import Base64Encoder
from nacl.public import PublicKey, SealedBox
env_path = os.path.expanduser('~/sandboxes/lucos_agent/.env')
with open(env_path, 'r') as f:
    content = f.read()
match = re.search(r'LUCOS_CI_PEM="((?:[^"\\\\]|\\\\.)*)"', content, re.DOTALL)
if not match:
    raise ValueError("LUCOS_CI_PEM not found")
pem = match.group(1)
if pem.count('\n') < 10:
    raise ValueError(f"PEM looks truncated: {pem.count(chr(10))} newlines")
pub_key = PublicKey("${DEP_PUB_KEY}", encoder=Base64Encoder)
encrypted = SealedBox(pub_key).encrypt(pem.encode('utf-8'), encoder=Base64Encoder)
print(json.dumps({"encrypted_value": encrypted.decode(), "key_id": "${DEP_KEY_ID}"}))
PYEOF
python3 "$DEP_SCRIPT" | \
    "$GH_AS_AGENT" --app lucos-system-administrator \
    "repos/lucas42/${REPO}/dependabot/secrets/LUCOS_CI_PRIVATE_KEY" \
    --method PUT --input /dev/stdin > /dev/null
rm "$DEP_SCRIPT"
echo "LUCOS_CI_PRIVATE_KEY set in Dependabot secrets."

# --- Step 7: Enable delete-branch-on-merge ---
"$GH_AS_AGENT" --app lucos-system-administrator \
    "repos/lucas42/${REPO}" \
    --method PATCH \
    -f delete_branch_on_merge=true > /dev/null
echo "delete_branch_on_merge enabled."

# --- Step 8: Branch protection on main ---
# Requires PRs pass CI (ci/circleci: lucos/build) before merge.
# No approval requirement and no strict mode — both would block Dependabot auto-merge.
# IMPORTANT: The exact required check name depends on the repo's CircleCI config.
# This sets the standard single-build check; add test/CodeQL checks manually if needed.
BP_BODY=$(mktemp /tmp/branch-protection-XXXXXX.json)
cat > "$BP_BODY" <<'BPEOF'
{
  "required_status_checks": {
    "strict": false,
    "contexts": ["ci/circleci: lucos/build"]
  },
  "enforce_admins": null,
  "required_pull_request_reviews": null,
  "restrictions": null
}
BPEOF
"$GH_AS_AGENT" --app lucos-system-administrator \
    "repos/lucas42/${REPO}/branches/main/protection" \
    --method PUT \
    --input "$BP_BODY" > /dev/null
rm "$BP_BODY"
echo "Branch protection enabled on main (required: ci/circleci: lucos/build)."
echo "NOTE: if the repo has test jobs or CodeQL, add them manually via the GitHub UI or API."

echo ""
echo "Done. Provisioned for lucas42/${REPO}:"
echo "  - LUCOS_CI_PRIVATE_KEY (full PEM, Python-extracted) — Actions + Dependabot secrets"
echo "  - LUCOS_CI_APP_ID — Actions + Dependabot secrets"
echo "  - fork-pr-contributor-approval = first_time_contributors_new_to_github"
echo "  - delete_branch_on_merge = true"
echo "  - Branch protection on main (required: ci/circleci: lucos/build, strict=false)"
echo ""
echo "Verify secrets by checking the next 'Generate GitHub App token' step in a workflow run:"
echo "  success  -> secrets are non-empty and valid"
echo "  skipped  -> one or both secrets are empty — re-run this script"
echo "  failure  -> secrets are non-empty but malformed — check PEM extraction"
