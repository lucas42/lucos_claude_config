---
name: inplace-write-vs-running-script
description: git checkout writes files in place (same inode); replacing a running bash script that way makes it execute a mixture of both versions and exit 0. Plus the disk==OLD discriminator for safe working-tree materialisation.
metadata:
  type: reference
---

## The hazard

**`git checkout <ref> -- <path>` writes in place — same inode** (rehearsed 2026-08-19). It is *not* an atomic rename.

Bash reads a script incrementally by byte offset, so replacing a running script in place makes it resume at a stale offset in the new bytes. Rehearsed result — a running script overwritten by a longer version:

```
./victim.sh: line 3: longer: command not found   <- executed a fragment of a COMMENT from the new file
REPLACEMENT — different offsets entirely
extra
--- exit=0
```

It executed a **mixture of both versions and exited 0**. No error, no signal. Applies to any interpreter that streams its source (bash, sh); less so to ones that slurp whole (python compiles the file first).

**Mitigation, verified:** write to a temp file in the same directory, `chmod` it, then `mv -f` over the target. The rename is atomic and allocates a new inode, so a running process keeps its old inode open and completes correctly, while disk gets the new content.

Generalises beyond git: any "self-updating script" or config-materialisation step must rename, never truncate-and-write.

## The disk==OLD discriminator (safe selective materialisation)

Problem: after `git reset --mixed origin/main`, working tree differs from index for BOTH "stale, nobody touched it" and "genuine local edit" — git state alone doesn't distinguish them (this is `lucos_claude_config#134`).

It does if you keep the **pre-sync** ref. Capture `OLD=$(git rev-parse HEAD)` *before* the fetch, then per differing path compare `git hash-object <path>` against `git rev-parse $OLD:<path>`:

| disk == OLD | disk == NEW | verdict |
|---|---|---|
| yes | no | STALE — safe to materialise (nobody touched it locally) |
| no | no | LOCAL EDIT — do not touch |
| no | yes | already current |

Rehearsed on a disposable repo: correctly materialised the stale path while leaving untouched both a genuine in-flight edit *and* a path that was **both** PR-changed and locally edited — the hard case — with no special handling.

**Why this beats merge-commit detection** (the approach the ticket proposed): indifferent to *how* `origin/main` advanced (PR merge, fast-forward, force-push), no commit-graph walk, fails safe by construction. It's the rule `git checkout` already applies internally — but `git merge --ff-only` can't be used here because it refuses **wholesale** if any one path would be clobbered, so a single agent's in-flight memory file would block materialising everything else. Per-path selectivity is the requirement.

**Corollary — the condition is NOT invisible.** A stale path shows in `git status --porcelain` as `M <path>` from the moment of the mixed reset. Any "we have no way to detect this" claim about it is wrong; the detector already exists and misattributes it. Check porcelain before asserting invisibility.

Related: [[reference_shared_claude_checkout_ref_state]], [[feedback_test_prescribed_values_against_rule]].
