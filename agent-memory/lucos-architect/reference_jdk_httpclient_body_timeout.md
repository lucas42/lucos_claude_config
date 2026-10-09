---
name: jdk-httpclient-body-timeout
description: java.net.http HttpRequest.timeout does not bound body reads on JDK 17/25 (ofInputStream AND ofString hang); JDK 27 does; fix = sendAsync + get(timeout)
metadata:
  type: reference
---

Tested 2026-10-09 against a server that sends headers then stalls the body (lucas42/lucos_media_manager#306):
- JDK 17.0.18 and Alpine openjdk25 25.0.4: body read blocks indefinitely under `ofInputStream()`; `send()` with `ofString()` also never returns.
- Temurin 27: request timeout covers the body (IOException "closed" at the deadline).
- Works on 25: `sendAsync(...).get(timeout)`; `cancel(true)` returned false (socket release unverified).

**How to apply:** any estate Java service using `HttpClient` with only `.timeout()` has an unbounded body read on its shipped JDK — check the *runtime* JDK (lucos_media_manager installs openjdk25 from Alpine, built on temurin-27). My first untested recommendation (`ofString`) was wrong — rehearse the fix, not just the bug.
