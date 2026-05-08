---
name: lucos_photos_android notes
description: Detailed technical notes for the lucos_photos_android Kotlin repo
type: project
---

- **Repo**: `https://github.com/lucas42/lucos_photos_android` (created 2026-03-04)
- **Language**: Kotlin, minSdk 26, targetSdk 36, compileSdk 36
- **Build**: Gradle 9.4.0 wrapper, AGP 9.1.0. CI uses `cimg/android:2025.01` (x86_64).
- **AGP 9.x migration**: `org.jetbrains.kotlin.android` plugin is **rejected** by AGP 9.0+ (hard error, not warning). Remove from both `build.gradle.kts` files and `libs.versions.toml`. Replace `kotlinOptions { jvmTarget }` with `kotlin { jvmToolchain(17) }`.
- **CodeQL for Android takes 15-30 min** — the `updated_at` field in GitHub API stays frozen at creation time during the run; this is a GitHub API quirk, not a stall. Do not flag slow CodeQL runs to lucos-site-reliability.
- **Key files**: `app/src/main/kotlin/eu/l42/lucos_photos_android/`
  - `PhotoSyncWorker.kt` — WorkManager CoroutineWorker, MediaStore query, incremental timestamp sync
  - `PhotoUploader.kt` — OkHttp multipart upload, retryable/non-retryable failure classification
  - `SyncPreferences.kt` — SharedPreferences wrapper for lastSyncTimestampMs
  - `Config.kt` — hardcoded SERVER_URL and API_KEY (placeholder in v1)
  - `PhotoSyncWorkerFactory.kt` — custom WorkerFactory for DI
  - `PhotoBackupApplication.kt` — manually inits WorkManager (auto-init disabled in manifest)
- **Tests**: Robolectric (sdk=34) for worker tests, plain JUnit + mockk for uploader tests
- **Local SDK**: Android SDK 36 + build-tools installed at `/opt/android-sdk` (as of 2026-03-10). Tests are configured with `@Config(sdk = [34])` so Robolectric still uses SDK 34 for test execution.
- **Conscrypt aarch64 issue**: Robolectric tests (`PhotoSyncWorkerTest`) fail locally with `UnsatisfiedLinkError: no conscrypt_openjdk_jni-linux-aarch_64` because `conscrypt-openjdk-uber:2.5.2` (Robolectric's dep) has no aarch64 native lib. Installing SDK 36 does NOT fix this — it is a Robolectric/Conscrypt issue unrelated to the Android SDK version. CI (x86_64) is unaffected. `PhotoUploaderTest` (plain JUnit + mockk, no Robolectric) passes locally fine.
- **WorkManager + Robolectric tests**: Use `@Config(sdk = [34], application = Application::class)` to prevent Robolectric from instantiating `PhotoBackupApplication`, whose `onCreate()` initialises WorkManager's static singleton. WorkManager's singleton interacts badly with Robolectric's per-test lifecycle. `TestListenableWorkerBuilder` bypasses WorkManager entirely — no WorkManager init is needed in tests.
- **Robolectric MediaStore seeding**: `ContentResolver.insert()` on MediaStore URIs returns a URI but stores nothing (no real MediaProvider registered). Use `RoboCursor` + `ShadowContentResolver.setCursor(uri, cursor)` to pre-set query results, plus `registerInputStream()` for `openInputStream()`. Do NOT rely on insert/query round-tripping.
- **`UploadResult` sealed class**: `Success` (201), `AlreadyUploaded` (200), `AuthFailure(message, errorKey)` (401/403), `Failure(message, retryable, errorKey)` (other errors). `errorKey` is the HTTP status code string or `"network"` / `"stream"` / `"exception"`.
- **`TelemetryReporter.reportSync` signature**: `durationMs`, `itemsFound`, `photosFound`, `videosFound`, `photosSynced`, `alreadyUploaded`, `errors`, `errorBreakdown: Map<String, Int>`, `relativePathSample`, `tiktokFiltered=0`, `tiktokSignalBreakdown=emptyMap()`, `succeeded`. Omits `error_breakdown` and `tiktok_signal_breakdown` from JSON when empty.
- **TikTok filtering (Android 11+)**: `TikTokClassifier` in `TikTokClassifier.kt` — multi-signal scoring (threshold 60). Videos only; photos are not filtered. `seedMediaStoreWithVideo` must include WIDTH, HEIGHT, DURATION columns — `RoboCursor.java:41` IllegalArgumentException if any projection column is missing from the cursor.
- **Run `PhotoUploaderTest`, `TelemetryReporterTest`, `TikTokClassifierTest` locally** (plain JUnit/mockk, no Robolectric). Run as: `./gradlew :app:testDebugUnitTest --tests "eu.l42.lucos_photos_android.PhotoUploaderTest" --tests "eu.l42.lucos_photos_android.TelemetryReporterTest" --tests "eu.l42.lucos_photos_android.TikTokClassifierTest"`
