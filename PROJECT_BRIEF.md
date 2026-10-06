# Place Memory Map — Product Brief

## Concept

A personal, map-first record of visited cafes, restaurants and food spots, using photo location metadata as a clue. Coordinates never prove a visit to a business; explicit confirmation is required.

## Implemented journey

1. Welcome and privacy explanation.
2. A real-memory map home; empty until the user confirms a photo.
3. Add photos and explicitly request selected/full library access.
4. Browse accessible images and available capture dates/GPS, 40 at a time.
5. Rank illustrative catalog venues within 300 m; confirm, choose another catalog venue, or skip.
6. Save confirmation in local SQLite, then group photos by place on the map/list.
7. Open a place to see photos/date-based visit days; remove local memories without deleting original photos.

The sample preview remains available separately and never becomes verified user history. Photo access and current location can be declined independently. The photo flow still works without a map token.

## Roadmap status

- Phase 1 Foundation: existing project/models/navigation preserved.
- Phase 2 Map: existing Mapbox/sample preview retained; real home also supports the map and one-shot recenter.
- Phase 3 Photos: accessible native image assets, GPS metadata, selected-library support and unavailable-photo placeholders.
- Phase 4 Matching: local Haversine radius/ranking; no remote venue service.
- Phase 5 Verification: explicit confirmation, alternative catalog selection, skip and save errors.
- Phase 6 Memories: SQLite confirmation, asset deduplication, grouped pins, local visit-day counts and removal.
- Phase 7 Polish/testing: implemented error/empty states and automated checks; live map tiles, recentering and grouped pins are validated on the simulator; physical-iPhone acceptance remains pending. See VALIDATION.md.

## Privacy and boundaries

Photos and confirmation records are processed/stored on device. No Firebase, Supabase, auth, backend, photo upload, social features, notifications, background location, cloud-sync feature, or production Places API. Photo thumbnails exist transiently in memory; full image files are not copied into the app database. Mapbox uses network requests for map tiles. Optional location only centers the map while using the app.

Limited library access is respected. Missing/invalid GPS prevents matching. If photo access is revoked or a photo is deleted, saved rows remain visible with an unavailable-image state until removed by the user. Skips are not persisted. Visit counts use unique photo calendar dates, not inferred arrival/departure sessions.

The small venue catalog contains fictitious demonstration businesses. Matching outside its coverage produces no automatic suggestion. Multiple photos per venue are supported; separate visits on the same day are counted together.

## Acceptance still needed

The public Mapbox token is configured in the ignored local file; live tiles, recentering and real grouped pin taps passed on the simulator. On a physical iPhone, validate selected-photo access, selection changes/revocation, a genuine geotagged photo, absent GPS, unavailable cloud photo, denied location and relaunch persistence. Signing requires the user's Apple development team. This agent did not commit or push; an external initial commit/rename appeared during the session (see VALIDATION.md).
