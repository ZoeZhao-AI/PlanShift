#if DEBUG
import SwiftUI
import WidgetKit

private enum WidgetPreviewData {
    static var activity: WidgetActivityTimeline.Entry {
        let now = Date.now
        let start = now.addingTimeInterval(3600)
        let activity = ItineraryActivity(
            tripId: UUID(), name: "Australian Museum", date: start,
            startTime: start, endTime: start.addingTimeInterval(7200),
            locationName: "College Street, Sydney", latitude: -33.8749, longitude: 151.2133,
            setting: .indoor, estimatedCost: 0
        )
        return .init(date: now, state: .activity(activity))
    }
}

#Preview("Small", as: .systemSmall) {
    PlanShiftWidget()
} timeline: {
    WidgetPreviewData.activity
    WidgetActivityTimeline.Entry(date: .now, state: .empty)
    WidgetActivityTimeline.Entry(date: .now, state: .unavailable)
}

#Preview("Medium", as: .systemMedium) {
    PlanShiftWidget()
} timeline: {
    WidgetPreviewData.activity
    WidgetActivityTimeline.Entry(date: .now, state: .empty)
    WidgetActivityTimeline.Entry(date: .now, state: .unavailable)
}

#Preview("Lock Screen", as: .accessoryRectangular) {
    PlanShiftWidget()
} timeline: {
    WidgetPreviewData.activity
    WidgetActivityTimeline.Entry(date: .now, state: .empty)
    WidgetActivityTimeline.Entry(date: .now, state: .unavailable)
}
#endif
