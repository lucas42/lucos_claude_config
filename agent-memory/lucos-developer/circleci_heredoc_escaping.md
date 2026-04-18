---
name: CircleCI v2.1 heredoc << escaping
description: In CircleCI config v2.1, << in shell commands must be escaped as \<< to avoid YAML anchor parse errors
type: feedback
---

In CircleCI config v2.1, the YAML parser treats `<<` as an anchor merge key **even inside block scalars** (`|` or `>`). This is non-standard YAML behaviour.

If a `run:` command contains a shell heredoc like `cat > file << 'EOF'`, CircleCI's parser raises:
```
Unclosed '<<' tag
('<<' must be escaped as '\<<' in config v2.1+)
```

**Fix:** escape every `<<` heredoc operator as `\<<` in the YAML. The CircleCI parser de-escapes `\<<` to `<<` before passing the string to the shell, so the shell sees the correct heredoc operator.

```yaml
- run:
    command: |
      cat > Dockerfile \<< 'EOF'
      FROM alpine:latest
      EOF
```

**Why:** CircleCI's YAML parser is non-conformant on this point — standard YAML block scalars are supposed to be literal strings where `<<` has no special meaning. Always escape heredocs when writing `run` steps in CircleCI v2.1 config.

**How to apply:** Any time you write a shell heredoc (`<< 'DELIMITER'` or `<< DELIMITER`) in a CircleCI `command: |` block, write `\<< 'DELIMITER'` instead.
