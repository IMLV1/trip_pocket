# TripPocket repository guidance

This repository contains the TripPocket individual mobile application project. At the initial planning stage, only design documents exist; inspect current files before assuming implementation status.

## Project documents

- Product scope and document index: `docs/README.md` and `docs/PROJECT_PROPOSAL.md`.
- UI and routes: `docs/FRONTEND_ARCHITECTURE.md`.
- Persistence and security contract: `docs/BACKEND_ARCHITECTURE.md`.
- Database schema and acceptance cases: `docs/DATABASE_DESIGN.md`.
- Approved text sharing feature: `docs/FEATURE_SHARE_PLAN.md`.
- Milestones and acceptance: `docs/IMPLEMENTATION_PLAN.md`.
- Reusable project skill: `docs/skills/trippocket-development/SKILL.md`.

Read the relevant contract before changing its implementation. The skill is a repository document; do not assume it has been installed globally.

## Implementation decisions

Use Flutter/Dart for Android, Thai Material 3 UI, Riverpod without code generation, go_router, Firebase Authentication, and Cloud Firestore. Use flutter_map for manual location selection and SharedPreferences for the local packing checklist. Select compatible package versions when implementation begins.

The user selected Flutter connecting directly to Firebase. Firebase is the backend; do not introduce a Go server or custom REST API for the current MVP. Use Firestore client SDK with Security Rules, not Admin credentials in the app.

The approved additional feature exports a text itinerary through share_plus after a preview. It does not grant recipients database access or add collaborative editing. Follow the fields and acceptance cases in docs/FEATURE_SHARE_PLAN.md.

Keep data access behind feature repositories. Store money as integer satang, travel dates as YYYY-MM-DD, and local time as minutes from midnight. Derive totals from activities. Scope all cloud data to the authenticated uid and local checklist keys to uid plus tripId. Dispose user state when switching accounts.

Do not delete a trip parent before its activities. Use the documented resumable deletion flow. Enforce ownership in Firestore Rules, not only in UI. Read the documented limitation for concurrent trip date edits.

Preserve docs when initializing Flutter. Do not add bookings, payments, collaborative editing, chat, or automatic route optimization without a scope change from the user. Do not deploy or create live cloud resources merely because a milestone describes them.

## Validation and reporting

Run checks relevant to the actual change: Flutter analysis/tests for code, Emulator rules tests for security changes, and Android device checks for maps/navigation/persistence. Distinguish fake, emulator, and live results. Report environment limitations accurately. Update milestone checkboxes only after verification, and synchronize affected documents when contracts change.

Keep user-facing explanations in Thai unless requested otherwise. Finish development reports with what changed, validation results, and outstanding work.


## Approved free V2.1 extension

Read docs/FEATURE_THAILAND_TRIP_PLANNER.md, the appended V2.1 contracts in frontend/backend/database documents, and docs/V21_TEST_GUIDE.md. The user approved daily multi-stop maps, ordering, categories, manual incoming travel costs, offline curated Chiang Mai search/recommendations, on-demand foreground location and external Maps URLs. Do not enable billing, Blaze, paid APIs or card-backed trials. No Go backend. Legacy activities decode without migration; saving upgrades to schema 2. Unknown costs are not free and stale segment costs must be excluded. Current GPS fixes are transient; never persist or share them by default. Read location only after the user requests it; no background tracking.

## Nationwide POI correction (approved 26 October 2026)

The user explicitly requires nationwide Thai search and selectable recommendations on the map. Production uses assets/thailand_pois.json via placeCatalogProvider (66,975 named community POIs across all 77 provinces), not the old Chiang Mai sample list, which remains only for deterministic regression fixtures. Read docs/FEATURE_NATIONWIDE_PLACES.md. Preserve ODbL attribution/data licensing and the reproducible importer. No public Nominatim/Overpass backend, paid API or billing. Public POI data remains device-local and separate from uid-scoped trip data. Selection must open details and require confirmation before saving a trip stop; unknown prices stay unknown.
