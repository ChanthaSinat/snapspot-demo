# Place Memory Map — Architecture

## App and navigation

Standard Flutter MaterialApp, Navigator and local StatefulWidget state. Welcome → privacy → MemoryMapScreen. The real-memory home is primary; MapScreen is an explicitly opened illustrative sample preview. DatabaseService is injectable through app/onboarding for widget tests; production uses native sqflite. No state-management or routing package was added.

Mapbox reads only the public ACCESS_TOKEN dart-define in main before constructing a map. VS Code and scripts/run_demo.sh can read the ignored mapbox.local.json. Missing token leaves the local photo and memory list usable. A map error/20-second timeout exposes a refresh action while retaining list access.

## Photo boundary

PhotoLibraryScreen explains access before PhotoService requests it. The photo_manager request option uses read/write Photos authorization (the platform API's library-reading level) but the app never calls photo editing/deletion APIs. Android requests image access and media-location permission; iOS purpose strings and limited-access configuration are present. No add-only photo permission is required.

PhotoService lists only accessible image assets in pages of 40; latlngAsync supplies GPS when available. Invalid/out-of-range/missing and the plugin's (0,0) missing-location sentinel cannot match. Dates come from AssetEntity.createDateTime. Permission state is rechecked on reads, and the photo list refreshes on foreground resume after Settings. There is no background worker/library monitor.

LocalPhotoView resolves an asset ID to an ephemeral thumbnail. Permissions, deleted assets, cloud-only assets and thumbnail errors return a visible placeholder. The service checks local availability first; the app never uploads images or persists thumbnail bytes. Asset IDs are identifiers, not file paths, and remain subject to library permissions.

## Matching and verification

PlaceMatcher uses Haversine distance, Earth radius 6,371,000 m, a 300 m inclusion radius and nearest-first sorting. Places load from the bundled illustrative JSON catalog. Suggestions never write storage.

VerificationScreen displays the photo/date, selectable ranked suggestions, an alternate catalog picker, Confirm and Skip. Saving requires a selected place, valid GPS and an accessible thumbnail; a busy flag prevents repeated saves. Only Confirm creates a verified Memory. No nearby match leaves selection empty until the user explicitly chooses a catalog venue. Skip writes nothing.

## SQLite

DatabaseService opens place_memories.db, schema version 1, on demand. Its opening future is shared during initialization and reset after failure so Retry can open it again. The memories table stores id, placeId, unique photoAssetId, ISO photoDate, photoLatitude, photoLongitude, verified and ISO createdAt. CHECK(verified = 1) and the repository guard reject unverified writes. Parameterized reads/removal and sqflite insert avoid SQL string interpolation of user data. Confirmation uses replace on conflict so a photo appears once.

Place IDs refer to the bundled catalog. Unknown catalog IDs are excluded from grouping; no catalog-editing feature is supplied. Removal affects database rows only. App uninstall removes local data. SQLite remains open for the app's lifetime; native integration testing explicitly closes/reopens it to check persisted rows.

## Real map and grouping

PlaceMemories groups verified rows by placeId, sorts most recent first, and counts unique local calendar dates as visit days. One photo pin per venue uses a recent available thumbnail and a badge with photo count. Rendering checks up to five recent photos before using a fallback pin. Pin taps and the list open grouped place details. All stored photos remain listed even when their images become unavailable.

The map reloads its annotation state after photo review, removal, explicit refresh or foreground resume. A revision check rejects stale annotation work after a reload; subscriptions and map-load timers are canceled on replacement/disposal. Sample annotations are managed separately in the existing MapScreen and never enter SQLite.

LocationService obtains one current position with permission/service/error distinctions and a timeout. The real map's recenter action has no location stream or SDK location puck. Only foreground location permissions exist; no background modes. The existing sample preview's active-map puck is retained.

## Validation and limits

Tests cover radius/ranking/invalid coordinates, verified grouping and visit-day semantics, SQLite confirmation/dedup/removal, consent navigation, sample separation and pin rendering. Native integration uses a synthetic geotagged image in a dedicated simulator to exercise PhotoKit, confirmation, native SQLite reopen and grouped details/removal. Test-only dependencies are integration_test and sqflite_common_ffi.

No backend, accounts, photo upload, cloud-sync feature, social features, notifications, background tracking, AI or remote Places API. Mapbox requires a public token and network for tiles. Android permissions are configured but its runtime has not been tested. See VALIDATION.md for verified results and pending physical-iPhone/live-map acceptance.
