---
name: trippocket-development
description: Develop and review the TripPocket Flutter Android application using its project architecture, Firebase data contracts, and implementation milestones. Use for TripPocket code, integration, or implementation planning in this repository.
---

# TripPocket Development

## Read the project contract

Resolve repository paths from this skill at `docs/skills/trippocket-development/`. Read the root [AGENTS.md](../../../AGENTS.md) and the relevant plan sections before making changes.

- UI, routes, and state: [Frontend Architecture](../../FRONTEND_ARCHITECTURE.md).
- Models, persistence, authorization, and deletion: [Backend Architecture](../../BACKEND_ARCHITECTURE.md).
- Database fields, examples, queries, indexes, and rules acceptance: [Database Design](../../DATABASE_DESIGN.md).
- Task order and acceptance criteria: [Implementation Plan](../../IMPLEMENTATION_PLAN.md).
- Scope and decisions: [Documentation Index](../../README.md).
- Text export through the native share sheet: [Share Plan](../../FEATURE_SHARE_PLAN.md).

The frontend and backend documents describe planned work. Inspect the repository before assuming code or Firebase configuration exists.

## Implement within the agreed scope

Target a Thai Android MVP with six screen types. Use Flutter, Riverpod without generation, go_router, Firebase Authentication, Firestore, a manually selected map coordinate, and a device-local packing checklist. Preserve existing code when implementation has already started; do not regenerate the project over it.

The selected architecture is Flutter directly calling Firebase client SDKs. Firebase provides the backend. Do not add a Go API to this MVP; protect database access using Firestore Security Rules and never embed Admin credentials in Flutter.

Use SDK-compatible dependency versions verified at implementation time. Keep fake and live repositories distinguishable. Missing Firebase credentials do not prevent building UI or emulator tests, but they do prevent claiming live integration passed.

Preserve the data contract: integer satang, date-only YYYY-MM-DD, timeMinutes, uid-scoped paths, and uid/tripId-scoped packing keys. Derive budget totals from activities. Do not treat an initial map camera coordinate as a confirmed location.

Trip deletion is resumable: mark deleting, reject new edits, remove children, remove parent, then clean local checklist. Surface interrupted deletions for retry. Read the backend limitations before changing trip date ranges or claiming multi-device consistency.

Map provider selection requires checking attribution, identification, and caching terms. Offline packing support does not imply offline maps or fully offline cloud editing.

The approved extra feature is sharing a text itinerary through share_plus after a preview. Keep sharing separate from Firestore access: no public links, shared permissions, or collaborative editing. Use the allowlisted fields in Share Plan and do not claim recipient delivery based on share-sheet status.

## Verify and hand off

Choose checks from the milestone being changed: domain tests for money/dates, widget checks for forms, emulator tests for authorization, and Android integration for maps and persistence. Check cross-account access whenever changing paths, providers, or rules. Do not invent test results or mark a milestone done merely because files exist.

Keep source documents synchronized when routes, schema, or scope change. Report changed behavior, checks run, actual results, and remaining blockers. Creating this plan or using this skill does not authorize deploying Firebase resources or adding paid services.


## Approved V2.1 scope

The user extended the original MVP with free multi-stop planning, categories, manual travel costs, offline Chiang Mai catalog search/recommendations and on-demand location plus external Maps navigation. Follow the appended V2.1 schema contracts and V21_TEST_GUIDE.md; the earlier MVP-only limitations do not remove this approved scope. Do not add paid APIs/billing or assume countrywide transit/fare coverage. Preserve legacy totals, unknown-cost semantics, segment invalidation and the resumable deletion contract. GPS is one-shot by user action, transient and not included in sharing.

## Nationwide POI correction (approved 26 October 2026)

The user explicitly requires nationwide Thai search and selectable recommendations on the map. Production uses assets/thailand_pois.json via placeCatalogProvider (67,074 named community POIs across all 77 provinces), not the old Chiang Mai sample list, which remains only for deterministic regression fixtures. Read docs/FEATURE_NATIONWIDE_PLACES.md. Preserve ODbL attribution/data licensing and the reproducible importer. No public Nominatim/Overpass backend, paid API or billing. Public POI data remains device-local and separate from uid-scoped trip data. Selection must open details and require confirmation before saving a trip stop; unknown prices stay unknown.
