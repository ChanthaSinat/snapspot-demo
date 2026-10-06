# Validation — 7 October 2026

## Verified

- Existing Phase 2 demo inspected and preserved in `/Users/chanthasinat/GoLoca/New GoLoca`; opened that folder in VS Code.
- Flutter 3.47.1 / Dart 3.13.1, Xcode 26.6 and CocoaPods 1.17.0. Android tooling is present. Flutter/Dart are absent from shell PATH, so launch commands use the explicit SDK path and VS Code uses the workspace SDK setting.
- `flutter pub get`: passed.
- `flutter analyze`: no issues found.
- `flutter test`: all 5 tests passed, including GPS ranking/radius, verified grouping, visit-day counts, SQLite unique-photo replacement/removal, consent navigation/sample separation and pin rendering.
- iOS simulator debug build: passed.
- Native integration on iPhone 17 Pro Max / iOS 26.5: passed through `flutter drive` using a prebuilt integration-test app.
- Native Photos permission actually returned **limited** after selecting only the synthetic GPS fixture through iOS's permission dialog. Simulator grant commands alone were insufficient for PhotoKit; the test now exercises the actual request used by the app.
- Native test read the fixture GPS and thumbnail, selected the nearest venue, tapped Confirm, saved a verified SQLite row, closed/reopened the database, read the persisted row, opened grouped home/details and removed its test memory. The original photo remains in the simulator's library.
- Local token file and `.env` are ignored by Git; tokens are not embedded in source/launch configuration. Launch helper syntax checked.

## Pending acceptance

- No public Mapbox token was supplied in mapbox.local.json. Live tiles, grouped real annotation taps, network-error recovery and location recenter with Mapbox have not been runtime-validated. The existing Phase 2 map and new grouped-map code compile, but compilation is not live-map proof.
- No physical iPhone connected: signing, genuine-device selected/full/revoked access, native Settings selection updates, cloud-only photo behavior and foreground-location denial/recenter need physical-device acceptance. No Apple team, bundle ID or OS version was changed.
- Android runtime/build has not been validated. Required foreground/image/limited-image/media-location permissions are configured.
- Visit counts use photo calendar dates, not inferred visit sessions. The three demo venues are illustrative and do not provide real-world coverage. Skips do not persist.

## Git

The repository is on main with no commits; existing project files were all untracked before this work. Nothing was staged, committed or pushed. This work modifies the existing demo and adds local-flow/test/docs/launch files only. Synced ChatGPT sources were not modified.
