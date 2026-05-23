---
name: python-inplace-write-perms
description: Python file rewrites via tempfile.mkstemp + shutil.move inherit the source's 0600 mode and break downstream readers. Set explicit permissions after the move.
metadata:
  type: feedback
---

When rewriting a file in-place via Python using `tempfile.mkstemp` + `shutil.move`, the resulting file gets `0600` (owner-only) permissions because `mkstemp` defaults to that mode and `shutil.move` preserves the source's mode. If the file is then read by another process (Docker container running as root, another user, a `git` hook running with limited privileges), reads fail with "permission denied".

**Why:** Stated 2026-05-23 after rewriting `pandoc-docx-reference.docx.template` via Python to inject a `<w:keepNext/>` style fix. The file came out `0600 lucas:lucas`. The next docker build copied it into the image (Docker COPY runs as root, so the in-image file was owned by root); when the docker container ran as `--user $(id -u):$(id -g)`, pandoc couldn't read the file ("permission denied"). The image had to be wiped and rebuilt.

**How to apply:**

When writing Python that rewrites an existing file in place, especially one that will be:
- copied into a Docker image at build time
- read by a process running as a different user
- consumed by git hooks
- mounted into a container

…explicitly set the mode after the move:

```python
import os, shutil, tempfile
fd, tmp = tempfile.mkstemp(suffix='.docx')
os.close(fd)
# ... write to tmp ...
shutil.move(tmp, target_path)
os.chmod(target_path, 0o664)  # explicit: don't leave it as the mkstemp default 0600
```

Or write the file directly via `with open(...) as f: f.write(...)` which uses the umask (typically 0644 / 0664), avoiding the mkstemp 0600 default entirely. Use the tempfile-and-move pattern only when atomic replacement is genuinely needed.

**Related**: [[write-tool-nbsp-flattening]] (related Python-vs-Write-tool gotcha for the same source-of-truth files).
