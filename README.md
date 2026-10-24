# PlanShift

PlanShift helps travellers when their plans are disrupted — rain, an attraction is closed, transport is delayed, or they are running out of time. The traveller picks the affected activity, picks the disruption, adjusts quick filters, and gets the **top 3 ranked alternative places** with short reasons. They can **replace** the activity or **save an alternative as a backup**. A **widget** shows the next activity and saved backups.

UTS 40005 Advanced iOS — Assessment 4 (team of 5). iOS 17.6+, SwiftUI, Core Data.

This branch contains only the **shared foundation** (domain models, errors, repository protocols, colour tokens, navigation shell with placeholder screens). Each module owner builds the rest of their module.

---

## Screenshots

<p>
  <img src="Screenshots/01-itinerary.png" width="200">
  <img src="Screenshots/02-activity-detail.png" width="200">
  <img src="Screenshots/03-plan-changed.png" width="200">
  <img src="Screenshots/04-top-alternatives.png" width="200">
  <img src="Screenshots/05-backups.png" width="200">
  <img src="Screenshots/06-backups-dark.png" width="200">
</p>

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
│   │   ├── Persistence/      (later, M3) PersistenceController, .xcdatamodeld
│   │   ├── Repositories/     (later, M1/M2/M4) Core Data implementations + mappers
│   │   └── Mocks/            (later, M3) in-memory repositories
│   ├── DesignSystem/         AppColors (+ components later)
│   └── Navigation/           AppRouter
├── Features/
│   ├── M1_Itinerary/         Views/ · ViewModels/ (later) · UseCases/ (later)
│   ├── M2_Recommendations/   Views/ · ViewModels/ (later) · UseCases/ (later)
│   ├── M3_Replace/           Views/ · ViewModels/ (later) · UseCases/ (later)
│   ├── M4_Backups/           Views/ · ViewModels/ (later) · UseCases/ (later)
│   └── M5_Settings/          Views/ · ViewModels/ (later) · UseCases/ (later) · SettingsView is owned by M3
└── Resources/                (later, M2) places.json
```

New files under `PlanShift/PlanShift/` join the app target automatically. Don't add `.gitkeep` files: they get copied into the app bundle and break the build.

---

## Module ownership

| Module | Area | Screens | Owner |
|---|---|---|---|
| M1 | Itinerary | M1-01 Itinerary · M1-02 Add/Edit Activity · M1-03 Activity Detail · M1-04 Delete Confirmation · M1-05 Empty State · M1-06 Create Trip | TBD |
| M2 | Recommendations | M2-01 Select Disruption · M2-02 Preference Filters · M2-03 Ranked Alternatives · M2-04 No Results | TBD |
| M3 | Replace & Settings | M3-01 Replace Confirmation · M3-02 Updated Itinerary Banner · M5-06 Settings | TBD |
| M4 | Backups | M4-01 Backups List · M4-02 Use a Backup · M4-03 Empty State · M4-04 Duplicate Toast | TBD |
| M5 | Widget & Location | M5-04 Location Pre-prompt · M5-05 Location Denied Banner · Widget | TBD |

## What each owner builds

Each owner replaces their placeholder screens and writes their own view models, use cases (with custom `DomainError`s) and tests, plus these foundation pieces:

- **M1 – Itinerary:** `TripEntity` and `ActivityEntity` in the Core Data model; `CoreDataTripRepository` and `CoreDataActivityRepository`; the tab and itinerary screens; use cases such as CreateTrip, AddActivity, UpdateActivity, DeleteActivity, FetchItinerary.
- **M2 – Recommendations:** `PlaceEntity`; the bundled places dataset (`Resources/places.json`, 40–60 Sydney places) and `importBundledPlacesIfNeeded`; `CoreDataPlaceRepository`; disruption defaults and the ranking logic (filter, score, top 3 with reasons).
- **M3 – Replace & Settings:** `PersistenceController` storing Core Data in the App Group (needed early by M1, M2 and M4); the in-memory mock repositories (all four protocols) and the unit test target setup; ReplaceActivity and UndoReplace; the Settings screen (M5-06), built against the LocationService interface from M5.
- **M4 – Backups:** `BackupEntity` and `CoreDataBackupRepository`; SaveBackup (duplicate check), RemoveBackup, FetchBackups.
- **M5 – Widget & Location:** the widget (next activity + backups, deep link `planshift://activity/<uuid>`); the location service and permission flow, with the LocationService interface defined early so M3 can build the Settings screen.

**Shared pieces need to be agreed:** the Core Data model file is shared by M1, M2, M3 and M4, so agree on entity names first and keep model changes in small PRs.

### How to connect M4 (Backups)

**Repositories.** M4 needs one `BackupRepository` and one `ActivityRepository`. Create each once and share it, so M2, M3 and M4 all see the same backups. The real backup repository is `CoreDataBackupRepository(container: persistence.container)`, available after its PR (`feat/m4-backup-repository`) merges. It only needs the `NSPersistentContainer` and is safe to call from any async code.

**Use cases.**
```swift
let fetchBackups  = FetchBackupsUseCase(repository: backupRepository)
let removeBackup  = RemoveBackupUseCase(repository: backupRepository)
let saveBackup    = SaveBackupUseCase(repository: backupRepository)          // also M2's BackupSaving
let fetchDay      = FetchDayActivitiesUseCase(repository: activityRepository)
```

**M4-01 Backups List** (Backups tab). Pass a view model and the current trip:
```swift
BackupsListView(
    viewModel: BackupsListViewModel(fetchBackups: fetchBackups, removeBackup: removeBackup),
    trip: currentTrip
)
```

**M4-02 Use a Backup** (sheet `.useBackup(backup:)`). Create a new view model for each backup:
```swift
UseBackupView(
    backup: backup,
    viewModel: UseBackupViewModel(backup: backup, fetchDayActivities: fetchDay),
    trip: currentTrip
)
```
Continue opens M3-01 with `router.present(.replaceConfirmation(...))`, so no extra wiring is needed.

**Replace these mocks.** In `RootView`, `BackupsListView()` and `UseBackupView(backup:)` are called without arguments, so they fall back to `.mocked()` view models and `PreviewSamples.trip`. Pass the real view model and trip as shown above. The `.mocked(...)` helpers in `BackupsListView.swift` and `UseBackupView.swift` can stay, because the previews use them. `RootView` also gives M3's `ReplaceActivityUseCase` its own `MockBackupRepository`. Give it the shared backup repository instead, so a replaced activity shows up in the Backups tab as "Original plan".

**M2 bookmarks.** `SaveBackupUseCase` already conforms to M2's `BackupSaving` (same duplicate rule, and it also saves only the day). In `RecommendationFlowViewModel.mocked(for:)`, M2 currently passes `RepositoryBackupSaver(repository: InMemoryBackupRepository())`. Pass `saveBackup` instead, and bookmarks will appear in the Backups tab:
```swift
RecommendationFlowViewModel(activity: activity, getAlternatives: ..., backups: saveBackup, location: ...)
```
After that, `InMemoryBackupRepository` and `RepositoryBackupSaver` in `M2IntegrationMocks.swift` are unused. The file also holds `MockLocationService`, so delete the whole file once M5's real location service is wired in too.

**"Original plan" backups are view-only for now.** These are `.activity` backups, which M3 creates when an activity is replaced. They show in the list and can be deleted, but M4-02 shows "Restoring an original plan isn't available yet." and keeps Continue disabled.

**Still to do during integration.**
- Add a relationship between BackupEntity and TripEntity (Trip has many Backups, cascade delete). BackupEntity only stores tripId for now because TripEntity wasn't on develop yet. The brief asks for a relational schema, so this is needed.
- Load the Core Data model only once in PersistenceController (for example a static model). Otherwise each in-memory controller in tests loads its own copy and Core Data logs "Multiple NSEntityDescriptions". CoreDataBackupRepository works around it, but other repositories will hit it too.
- For M5: the widget needs target membership for the model file, PersistenceController, BackupEntity.swift, BackupEntityMapper.swift and CoreDataBackupRepository.swift.

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
