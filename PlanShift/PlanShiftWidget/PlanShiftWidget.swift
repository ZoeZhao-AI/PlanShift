import SwiftUI
import WidgetKit

extension WidgetActivityTimeline.Entry: TimelineEntry {}

struct NextActivityProvider: TimelineProvider {
    typealias Entry = WidgetActivityTimeline.Entry

    func placeholder(in context: Context) -> Entry {
        Entry(date: .now, state: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        load { timeline in
            completion(timeline.entries[0])
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        load { timeline in
            completion(Timeline(entries: timeline.entries, policy: .after(timeline.reloadAfter)))
        }
    }

    private func load(completion: @escaping (WidgetActivityTimeline) -> Void) {
        Task { @MainActor in
            do {
                let persistence = try PersistenceController()
                let loader = GetWidgetTimeline(
                    trips: CoreDataTripRepository(container: persistence.container),
                    activities: CoreDataActivityRepository(container: persistence.container)
                )
                completion(try await loader.execute())
            } catch {
                completion(.unavailable(now: .now))
            }
        }
    }
}

struct PlanShiftWidget: Widget {
    let kind = WidgetActivityTimeline.widgetKind

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
