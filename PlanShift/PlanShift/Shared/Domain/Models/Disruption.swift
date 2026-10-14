// Module: Shared – domain model.

import Foundation

/// The kinds of disruption a traveller can report (M2-01).
nonisolated enum Disruption: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case rainyWeather
    case attractionClosed
    case transportDelay
    case runningOutOfTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rainyWeather: "Rainy weather"
        case .attractionClosed: "Attraction closed"
        case .transportDelay: "Transport delay"
        case .runningOutOfTime: "Running out of time"
        }
    }

    var subtitle: String {
        switch self {
        case .rainyWeather: "Find something indoors"
        case .attractionClosed: "Find a similar place nearby"
        case .transportDelay: "Stay close to where you are"
        case .runningOutOfTime: "Find something quick"
        }
    }

    /// SF Symbol name.
    var symbolName: String {
        switch self {
        case .rainyWeather: "cloud.rain.fill"
        case .attractionClosed: "xmark.octagon.fill"
        case .transportDelay: "tram.fill"
        case .runningOutOfTime: "hourglass"
        }
    }
}
