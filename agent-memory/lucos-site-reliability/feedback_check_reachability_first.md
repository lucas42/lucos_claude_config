---
name: Check file reachability from entry point before diagnosing "deployed code doesn't behave as expected"
description: When code is in source/git/container but runtime behaviour proves it isn't running, the simplest cause is that the file isn't reached from the active entry point — check that before reasoning about minifiers, caches, or other complex causes
type: feedback
---

When investigating "the change is deployed but doesn't behave as expected" — i.e. the code is in the source tree, in git, in the production container, but the runtime proves it isn't running — **the first hypothesis to check is "is the file containing the change actually reachable from a live entry point?"**

Bundlers (webpack, esbuild, rollup, vite, etc.) will silently drop unreachable code regardless of whether the source map shows the original file. The source map embeds the source webpack *saw* (which is what tricked me), not what survived tree-shaking. So a source map that contains the new code is not proof that the new code is in the runtime bundle.

**Why:** lucas42 corrected my diagnosis on 2026-05-06 during the lucos#126 measurement run. I wrote a long, confident analysis blaming terser dead-code elimination of `post(...).catch(noop)` because the line was missing from the bundle but present in the source map. The actual cause was simpler: `lucos_media_seinn` has two audio player implementations (`web-player.js` and `audio-element-player.js`), and `src/client/player.js` imports both but only destructures and uses `webPlayer`. The beacon was added to the unused implementation. Webpack correctly identified the entire file as dead code and dropped it. The terser-DCE story was technically possible but wrong — and crucially, "check the import chain" is much faster to verify than "reason about minifier optimisation passes."

**How to apply:**

When something deployed isn't behaving as expected, run this check **before** any hypothesis involving:
- Minifier / terser optimisations
- Webpack tree-shaking misconfigurations
- Service-worker / browser cache staleness  
- Docker layer caching
- Build-tool bugs

Concrete checks:
1. Read the entry point file (e.g. `src/client/index.js`, `main.go`, `__main__.py`).
2. Trace the imports/requires from there. Does the change you expect to be running live in a file that's imported from this chain?
3. **Read past the `import` line** — is the imported symbol actually *used*? An imported-but-unused symbol triggers tree-shaking. Look for destructuring, function calls, JSX references, etc.
4. If two implementations exist side-by-side (a common pattern: legacy + new, basic + fancy, server + browser), verify which one the entry point actually wires up.
5. Only then reason about more elaborate causes.

**Specific to JavaScript bundlers**: the source map's `sourcesContent` is misleading evidence in this class of bug. It proves webpack's loader saw the file, NOT that the bundle contains the file's logic. Don't use source-map embedding as proof the code shipped.

**Specific to lucos_media_seinn**: `src/client/player.js` has an explicit comment at the top describing both player implementations. Reading that comment first would have saved time.
