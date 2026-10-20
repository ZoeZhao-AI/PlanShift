import WidgetKit

/// Call from the app after itinerary, current-trip or backup changes are committed.
@MainActor
struct WidgetTimelineReloader {
    private let reloadAction: (String) -> Void

    init(reload: @escaping (String) -> Void = { WidgetCenter.shared.reloadTimelines(ofKind: $0) }) {
        reloadAction = reload
    }

    /// Requests an update for all sizes of the PlanShift widget; timing is controlled by WidgetKit.
    func requestReload() {
        reloadAction(WidgetActivityTimeline.widgetKind)
    }

    /// Wrap the complete save operation, not each intermediate write in a replacement.
    func afterSuccessfulChange<Result>(_ change: @MainActor () async throws -> Result) async rethrows -> Result {
        let result = try await change()
        // A completed save still needs a reload even if its caller is cancelled afterwards.
        requestReload()
        return result
    }
}
