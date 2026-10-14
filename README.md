# PlanShift

PlanShift helps travellers when their plans are disrupted — rain, an attraction is closed, transport is delayed, or they are running out of time. The traveller picks the affected activity, picks the disruption, adjusts quick filters, and gets the **top 3 ranked alternative places** with short reasons. They can **replace** the activity or **save an alternative as a backup**. A **widget** shows the next activity and saved backups.

UTS 40005 Advanced iOS — Assessment 4 (team of 5). iOS 17.6+, SwiftUI, Core Data.

This branch contains only the **shared foundation** (domain models, errors, repository protocols, colour tokens, navigation shell with placeholder screens). Each module owner builds the rest of their module.

---

## Architecture

MVVM + Use Case layer + Repository pattern.

```
 View (SwiftUI)              layout and user input only — no Core Data, no business rules
   │  calls methods  ▲ observes state
 ViewModel                   @Observable @MainActor — screen state; talks only to use cases
   │  execute(...)   ▲ domain models
 Use Case                    one business action per struct; throws DomainError
   │                 ▲ domain models
 Repository protocol         Shared/Domain/Repositories (interfaces)
   │
 ├─ Core Data repository     real app; maps NSManagedObject ⇄ domain model
 └─ Mock repository          in-memory; previews and unit tests
   │
 Core Data store             SQLite in the App Group group.com.utsstudent.zhaoziying.planshift
                             (shared with the widget)
```

**Data flow example — save an alternative as a backup:**
`RankedAlternativesView` → `RecommendationsViewModel.save(place)` → `SaveBackupUseCase.execute(...)` checks for duplicates (throws `DomainError.duplicateBackup`) → `BackupRepository.save(_:)` → Core Data.

**Rules**
- Domain models are `nonisolated`, `Sendable` structs/enums with no SwiftUI or Core Data imports.
- `NSManagedObject` types never leave the data layer.
- Navigation (tab, sheets, Itinerary path, deep links) goes through `AppRouter`.
- Colours come from `AppColors` (Light and Dark Mode). Use text styles (`.headline`), never fixed font sizes. Touch targets must be at least 44×44 pt, and icon-only buttons need accessibility labels.
- Zero warnings, zero errors.

---

## Folder structure

`(later)` = folders added by module owners.

```
PlanShift/PlanShift/
├── App/                      PlanShiftApp, RootView (tabs + sheets), PreviewSamples
├── Shared/
│   ├── Domain/
│   │   ├── Models/           Trip, ItineraryActivity, Place, BackupOption, Disruption, filters, ReasonTag, …
│   │   ├── Errors/           DomainError
│   │   └── Repositories/     TripRepository, ActivityRepository, PlaceRepository, BackupRepository
│   ├── Data/                 (later)
│   │   ├── Persistence/      (later, M5) PersistenceController, .xcdatamodeld
│   │   ├── Repositories/     (later, M1/M2/M4) Core Data implementations + mappers
│   │   └── Mocks/            (later, M3) in-memory repositories
│   ├── DesignSystem/         AppColors (+ components later)
│   └── Navigation/           AppRouter
├── Features/
│   ├── M1_Itinerary/         Views/ · ViewModels/ (later) · UseCases/ (later)
│   ├── M2_Recommendations/   Views/ · ViewModels/ (later) · UseCases/ (later)
│   ├── M3_Replace/           Views/ · ViewModels/ (later) · UseCases/ (later)
│   ├── M4_Backups/           Views/ · ViewModels/ (later) · UseCases/ (later)
│   └── M5_Settings/          Views/ · ViewModels/ (later) · UseCases/ (later)
└── Resources/                (later, M2) places.json
```

New files under `PlanShift/PlanShift/` join the app target automatically. Don't add `.gitkeep` files: they get copied into the app bundle and break the build.

---

## Module ownership

| Module | Area | Screens | Owner |
|---|---|---|---|
| M1 | Itinerary | M1-01 Itinerary · M1-02 Add/Edit Activity · M1-03 Activity Detail · M1-04 Delete Confirmation · M1-05 Empty State · M1-06 Create Trip | TBD |
| M2 | Recommendations | M2-01 Select Disruption · M2-02 Preference Filters · M2-03 Ranked Alternatives · M2-04 No Results | TBD |
| M3 | Replace | M3-01 Replace Confirmation · M3-02 Updated Itinerary Banner | TBD |
| M4 | Backups | M4-01 Backups List · M4-02 Use a Backup · M4-03 Empty State · M4-04 Duplicate Toast | TBD |
| M5 | Settings & Widget | M5-04 Location Pre-prompt · M5-05 Location Denied Banner · M5-06 Settings · Widget | TBD |

## What each owner builds

Each owner replaces their placeholder screens and writes their own view models, use cases (with custom `DomainError`s) and tests, plus these foundation pieces:

- **M1 – Itinerary:** `TripEntity` and `ActivityEntity` in the Core Data model; `CoreDataTripRepository` and `CoreDataActivityRepository`; the tab and itinerary screens; use cases such as CreateTrip, AddActivity, UpdateActivity, DeleteActivity, FetchItinerary.
- **M2 – Recommendations:** `PlaceEntity`; the bundled places dataset (`Resources/places.json`, 40–60 Sydney places) and `importBundledPlacesIfNeeded`; `CoreDataPlaceRepository`; disruption defaults and the ranking logic (filter, score, top 3 with reasons).
- **M3 – Replace:** the in-memory mock repositories (all four protocols) and the unit test target setup; ReplaceActivity and UndoReplace.
- **M4 – Backups:** `BackupEntity` and `CoreDataBackupRepository`; SaveBackup (duplicate check), RemoveBackup, FetchBackups.
- **M5 – Settings & Widget:** `PersistenceController` storing Core Data in the App Group; the widget (next activity + backups, deep link `planshift://activity/<uuid>`); the location service and permission flow.

**Shared pieces need to be agreed:** the Core Data model file is shared by M1, M2, M4 and M5, so agree on entity names first and keep model changes in small PRs.

---

## Git rules

- **`main`** — submission only. Never commit to it directly.
- **`develop`** — integration branch.
- **Feature branches** from `develop`, e.g. `feat/m2-ranking`, `fix/m4-duplicate-toast`.
- **Conventional Commits:** `feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`.
- **Pull requests into `develop`**, with **one reviewer** approval. The build must have zero warnings.
- Commit your own work from your own account — individual contributions are assessed.
- Never commit `.DS_Store` or `xcuserdata/`.

---

## Build

```bash
xcodebuild -project PlanShift/PlanShift.xcodeproj -scheme PlanShift \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Third-party packages

None.
