# Validation — 7 October 2026

## Verified

- Existing Phase 2 demo inspected and preserved in `/Users/chanthasinat/GoLoca/New GoLoca`; opened that folder in VS Code.
- Flutter 3.47.1 / Dart 3.13.1, Xcode 26.6 and CocoaPods 1.17.0. Android tooling is present. Flutter/Dart are absent from shell PATH, so launch commands use the explicit SDK path and VS Code uses the workspace SDK setting.
- `flutter pub get`: passed.
- `flutter analyze`: no issues found.
- `flutter test`: all 9 tests passed, including GPS ranking/radius, verified grouping, visit-day counts, SQLite unique-photo replacement/removal, consent navigation/sample separation and pin rendering.
- Added regression coverage for foreground-location consent, permanent denial, disabled services and timeouts. Fixed map reload during a location prompt and delayed photo pins overriding a recenter action.
- iOS simulator debug build: passed.
- Native integration on iPhone 17 Pro Max / iOS 26.5: passed through `flutter drive` using a prebuilt integration-test app.
- Native Photos permission actually returned **limited** after selecting only the synthetic GPS fixture through iOS's permission dialog. Simulator grant commands alone were insufficient for PhotoKit; the test now exercises the actual request used by the app.
- Native test read the fixture GPS and thumbnail, selected the nearest venue, tapped Confirm, saved a verified SQLite row, closed/reopened the database, read the persisted row, opened grouped home/details and removed its test memory. The original photo remains in the simulator's library.
- Normal app launch, onboarding, empty real-memory home and photo-consent screen were visually inspected. Declining the native Photos prompt produced the expected unavailable-access state with Settings/Refresh controls. On this simulator, the Settings link opened the system Settings home rather than directly opening app settings.
- Local token file and `.env` are ignored by Git; tokens are not embedded in source/launch configuration. Launch helper syntax checked.

- User-supplied public Mapbox token saved only in ignored mapbox.local.json with mode 0600. Live Phnom Penh tiles loaded. The location button recentered to a synthetic Siem Reap simulator position after the native foreground permission prompt.
- Selected only two synthetic GPS photos through limited Photos access, confirmed both for Garden Coffee Demo, and observed one real photo pin with badge 2. Tapping it opened two confirmed thumbnails and one visit day. Simulator import assigned both assets the same creation date; distinct-day grouping is covered by automated tests. Relaunch preserved the grouped place. Both synthetic test memories were then removed through the app; original fixture photos remain. The final photo-detail layout and singular/plural labels were visually verified, and the synthetic simulator location was cleared.

## Pending acceptance

- Network-error recovery has not been deliberately exercised against an offline or rejected-token Mapbox session. Missing-token and denied-photo states were inspected; the map retains a list fallback and refresh control.
- No physical iPhone connected: signing, genuine-device selected/full/revoked access, native Settings selection updates, cloud-only photo behavior and foreground-location denial/recenter need physical-device acceptance. No Apple team, bundle ID or OS version was changed.
- Android runtime/build has not been validated. Required foreground/image/limited-image/media-location permissions are configured.
- Visit counts use photo calendar dates, not inferred visit sessions. The three demo venues are illustrative and do not provide real-world coverage. Skips do not persist.

## Git

At initial inspection, the repository was on main with no commits and all project files were untracked. During this session, another process created commit 5afcd2b (Initial SnapSpot demo foundation) and renamed the folder to /Users/chanthasinat/GoLoca/snapspot-demo. This agent did not stage, commit, push or undo that external commit/rename. Final documentation/copy corrections remain local changes. This work modifies the existing demo and adds local-flow/test/docs/launch files only. Synced ChatGPT sources were not modified.
