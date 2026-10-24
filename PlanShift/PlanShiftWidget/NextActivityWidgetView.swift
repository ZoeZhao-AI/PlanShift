import SwiftUI
import UIKit
import WidgetKit

struct NextActivityWidgetView: View {
    let entry: WidgetActivityTimeline.Entry
    let family: WidgetFamily
    let renderingMode: WidgetRenderingMode

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isAccessory: Bool { family == .accessoryRectangular }
    private var usesBrandColors: Bool { renderingMode == .fullColor && !isAccessory }
    private var textColor: Color { usesBrandColors ? AppColors.textPrimary : .primary }
    private var secondaryColor: Color { usesBrandColors ? AppColors.textSecondary : .secondary }
    private var accentColor: Color { usesBrandColors ? AppColors.primary : .primary }

    var body: some View {
        Group {
            switch entry.state {
            case .activity(let activity):
                activityContent(activity)
                    .privacySensitive()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(activityDescription(activity))
                    .accessibilityHint("Opens activity details in PlanShift")
            case .empty:
                statusContent(
                    title: "No upcoming activities",
                    compactTitle: "Nothing next",
                    message: "Add an activity in PlanShift.",
                    symbol: "calendar.badge.plus"
                )
            case .unavailable:
                statusContent(
                    title: "Can't load itinerary",
                    compactTitle: "Can't load",
                    message: "Open PlanShift to check your plans.",
                    symbol: "exclamationmark.arrow.triangle.2.circlepath"
                )
            }
        }
        .foregroundStyle(textColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(activityURL)
    }

    @ViewBuilder
    private func activityContent(_ activity: ItineraryActivity) -> some View {
        if isAccessory {
            ViewThatFits(in: .vertical) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.startTime, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption)
                        .widgetAccentable()
                        .lineLimit(1)
                    Text(activity.name)
                        .font(.headline)
                        .lineLimit(2)
                }
                compactActivity(activity)
            }
        } else if !dynamicTypeSize.isAccessibilitySize, let photo = activityPhoto(activity) {
            if family == .systemMedium {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        heading
                        Text(activity.startTime, style: .time)
                            .font(.title2.weight(.semibold))
                            .lineLimit(1)
                        activityName(activity)
                        location(activity)
                        activityDate(activity)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 104, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityHidden(true)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 46)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityHidden(true)
                    HStack {
                        heading
                            .labelStyle(.iconOnly)
                        Spacer(minLength: 4)
                        Text(activity.startTime, style: .time)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                    }
                    activityName(activity)
                }
            }
        } else if family == .systemMedium && !dynamicTypeSize.isAccessibilitySize {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    heading
                    Text(activity.startTime, style: .time)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                    activityDate(activity)
                }
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    activityName(activity)
                    location(activity)
                    Label(activity.setting.title,
                          systemImage: activity.setting == .indoor ? "building.2" : "sun.max")
                        .font(.caption)
                        .foregroundStyle(secondaryColor)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            ViewThatFits(in: .vertical) {
                VStack(alignment: .leading, spacing: 6) {
                    heading
                    Text(activity.startTime, style: .time)
                        .font(.title2.weight(.semibold))
                        .lineLimit(1)
                    activityDate(activity)
                    activityName(activity)
                    if !dynamicTypeSize.isAccessibilitySize {
                        location(activity)
                    }
                }
                compactActivity(activity)
            }
        }
    }

    private func activityPhoto(_ activity: ItineraryActivity) -> UIImage? {
        for name in [activity.locationName, activity.name] {
            let assetName = name
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .joined(separator: "-")
            if let image = UIImage(named: assetName) { return image }
        }
        return nil
    }

    private var heading: some View {
        Label("Up next", systemImage: "calendar")
            .font(.caption.weight(.semibold))
            .foregroundStyle(accentColor)
            .widgetAccentable()
            .lineLimit(1)
    }

    private func activityName(_ activity: ItineraryActivity) -> some View {
        Text(activity.name)
            .font(.headline)
            .lineLimit(2)
    }

    private func activityDate(_ activity: ItineraryActivity) -> some View {
        Text(activity.startTime, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
            .font(.caption)
            .foregroundStyle(secondaryColor)
            .lineLimit(1)
    }

    private func location(_ activity: ItineraryActivity) -> some View {
        Text(activity.locationName.isEmpty ? "Location not set" : activity.locationName)
            .font(.caption)
            .foregroundStyle(secondaryColor)
            .lineLimit(2)
    }

    private func compactActivity(_ activity: ItineraryActivity) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(activity.startTime, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(.caption2)
                .foregroundStyle(secondaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.35)
            activityName(activity)
                .minimumScaleFactor(0.5)
        }
    }

    @ViewBuilder
    private func statusContent(title: String, compactTitle: String, message: String, symbol: String) -> some View {
        if isAccessory {
            ViewThatFits(in: .vertical) {
                Label(title, systemImage: symbol)
                    .font(.headline)
                    .lineLimit(2)
                Text(compactTitle)
                    .font(.caption)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
            }
            .accessibilityLabel("\(title). \(message)")
        } else {
            ViewThatFits(in: .vertical) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: symbol)
                        .font(.title2)
                        .foregroundStyle(accentColor)
                        .widgetAccentable()
                        .accessibilityHidden(true)
                    Text(title).font(.headline)
                    Text(message).font(.caption).foregroundStyle(secondaryColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(compactTitle).font(.headline).lineLimit(1).minimumScaleFactor(0.35)
                    Text("Open PlanShift")
                        .font(.caption)
                        .foregroundStyle(secondaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.35)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title). \(message)")
            .accessibilityHint("Opens PlanShift")
        }
    }

    private var activityURL: URL? {
        guard case .activity(let activity) = entry.state else { return nil }
        return WidgetActivityLink.url(for: activity.id)
    }

    private func activityDescription(_ activity: ItineraryActivity) -> String {
        let start = activity.startTime.formatted(date: .complete, time: .shortened)
        let place = activity.locationName.isEmpty ? "Location not set" : activity.locationName
        return "Next activity: \(activity.name). \(start). \(place)."
    }
}
