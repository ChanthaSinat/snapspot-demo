# Place Memory Map

A local Flutter demo that turns explicitly confirmed photo visits into a personal map. No backend, accounts, cloud photo upload, social features, notifications, background location, or production Places API.

## Current state

Phases 1–6 are implemented. The app opens a real-memory home with an empty state, not sample visits. Add photos → grant selected/full photo access → browse accessible images → review nearby local venues → Confirm / Choose another / Skip → saved place memories. The compass icon opens the separate, clearly labeled Phase 2 sample preview.

Phase 7 adds permission/storage/map/photo error states, pagination, local removal, tests, simulator validation and these docs. Live Mapbox tiles, recentering and grouped photo-pin details were validated on the simulator. Physical-iPhone permission/signing checks remain required.

## Run in VS Code

Open this folder. The workspace setting points to `/Users/chanthasinat/Develop/flutter`, because Flutter/Dart are not currently in the terminal PATH. Choose **Local photo demo** and your iOS Simulator, then press F5. This runs the photo/verification/storage flow without a map token.

To enable the live map, create `mapbox.local.json` in this folder:

```json
{"ACCESS_TOKEN":"pk.YOUR_PUBLIC_TOKEN"}
```

Use a public `pk.` token from [Mapbox access tokens](https://account.mapbox.com/access-tokens/). The file is ignored by Git. Never use a secret `sk.` token or put tokens in source files. Choose **Mapbox demo (local token)** in VS Code. Public mobile tokens are embedded in the built app, so they cannot be treated as server secrets.

Terminal alternative:

```sh
/Users/chanthasinat/Develop/flutter/bin/flutter pub get
./scripts/run_demo.sh -d 28CD3F4F-1C92-492B-86C0-8DB9FB3E0486
```

The script uses the ignored token file when present. Without it, the local flow remains usable. Mapbox still requires network access for map tiles; local-only refers to photo processing and memory persistence.

## Photos, matching and memories

Photo permission is requested only after **Add photos → Choose photo access**. Limited access is supported; use **Manage selected photos** to update the selection and **Refresh photos** after changing permissions. The app pages 40 accessible images at a time. Images without usable GPS remain visible but cannot be verified. Cloud-only/unavailable images show a fallback: download them in Apple's Photos app first.

The three venues in `lib/data/demo_places.json` are illustrative Phnom Penh demo businesses, not a production directory. Matching uses Haversine distance within 300 m and ranks suggestions nearest first. GPS never verifies a visit. You may choose another catalog venue explicitly when no suggestion fits, or skip. Skipping saves nothing and leaves the photo available for later review.

Only confirmation writes SQLite records. The database stores photo asset IDs, photo dates/GPS and place IDs, never copies full photos. Duplicate asset IDs replace the existing memory rather than create duplicates. Saved photos group by venue; one local calendar date counts as one visit day, which is an approximation. Pin badges count photos. Place details show all confirmed photos and dates. Removing a memory deletes its local row only; original photos remain in the library. Revoked access or deleted photos produce placeholders while saved metadata stays available. Uninstalling the app removes its local data.

Current location is optional and requested only by the location button in the real map. It fetches one foreground position with a timeout; there is no location stream or background permission. The separate sample preview retains its foreground location behavior. Mapbox receives map requests; personal photo thumbnails and confirmation rows are not uploaded by this app.

## Validation

```sh
/Users/chanthasinat/Develop/flutter/bin/flutter analyze
/Users/chanthasinat/Develop/flutter/bin/flutter test
/Users/chanthasinat/Develop/flutter/bin/flutter build ios --simulator --debug
```

The unit/widget suite covers matching radius/order/invalid GPS, verified-only grouping and visit days, SQLite confirmation/duplicate/removal behavior, onboarding, photo-consent navigation, sample separation, pin rendering, and foreground-location consent/denial/disabled-service/timeout behavior. The SQLite FFI dependency is test-only.

Native integration test: use a test simulator, use the script to build/install the native test and add the synthetic fixture. When iOS asks, choose Limit Access and select only the fixture showing the street-food stall. Simulator permission grants alone did not establish PhotoKit authorization on this runtime. Never run this fixture test on a personal phone/library.

```sh
./scripts/test_simulator.sh 28CD3F4F-1C92-492B-86C0-8DB9FB3E0486
```

This reads real native photo GPS/thumbnails, taps confirmation, closes/reopens SQLite, checks the grouped home/details, and removes its test memory. It is opt-in. The fixture is a bundled sample image with synthetic coordinates/date. Automated integration results and remaining manual checks are recorded in `VALIDATION.md`.

For a physical iPhone: connect/trust it, enable Developer Mode, choose your development team in `ios/Runner.xcworkspace`, and use a unique bundle ID. No physical device is currently connected. No signing team or OS version has been changed.

## Layout

- `lib/screens/map/memory_map_screen.dart`: real memory home, place grouping, Mapbox pins and details.
- `lib/screens/map/map_screen.dart`: separate illustrative sample map.
- `lib/screens/photos/`: consent and paged accessible photos.
- `lib/screens/verification/`: nearby suggestions, alternatives and explicit confirmation.
- `lib/services/`: photo access, distance matching, local SQLite and one-shot location.
- `lib/widgets/`: ephemeral photo thumbnail and photo-pin rendering.
- `test/` and `integration_test/`: automated checks and synthetic native fixture.

Tooling inspected: Flutter 3.47.1, Dart 3.13.1, Xcode 26.6, CocoaPods 1.17.0; iPhone 17 Pro Max simulator on iOS 26.5. Android photo permissions are configured, but Android runtime behavior has not been validated.
