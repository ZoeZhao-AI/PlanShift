import SwiftUI
import WidgetKit

extension WidgetActivityTimeline.Entry: TimelineEntry {}

struct NextActivityProvider: TimelineProvider {
    typealias Entry = WidgetActivityTimeline.Entry

    func placeholder(in context: Context) -> Entry {
        Entry(date: .now, state: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: .now, state: .unavailable))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // M1's persistent activity repository and current-trip selection are not wired yet.
        // Keep this distinct from a successfully loaded itinerary with no upcoming activities.
        let timeline = WidgetActivityTimeline.unavailable(now: .now)
        completion(Timeline(entries: timeline.entries, policy: .after(timeline.reloadAfter)))
    }
}

struct PlanShiftWidget: Widget {
    let kind = "PlanShiftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextActivityProvider()) { entry in
            PlanShiftWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next activity")
        .description("See your next planned activity and tap to open its details.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct PlanShiftWidgetEntryView: View {
    let entry: WidgetActivityTimeline.Entry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        NextActivityWidgetView(entry: entry, family: family, renderingMode: renderingMode)
            .containerBackground(for: .widget) {
                AppColors.backgroundGradient
            }
    }
}
