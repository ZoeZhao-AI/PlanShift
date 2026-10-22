// Module: Shared – loads M1's current trip for screens that need one (M4 Backups).

import SwiftUI

/// Loads the current trip from `TripRepository` and hands it to `content`.
/// Shows a prompt to create a trip when there is none, and reloads when `reloadOn` changes
/// (e.g. when the user switches tabs after creating a trip).
struct CurrentTripView<Content: View, Trigger: Hashable>: View {
    let trips: any TripRepository
    let reloadOn: Trigger
    @ViewBuilder let content: (Trip) -> Content

    @State private var phase: Phase = .loading

    private enum Phase {
        case loading
        case loaded(Trip?)
        case failed(String)
    }

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView()
            case .loaded(let trip?):
                content(trip)
            case .loaded(nil):
                ContentUnavailableView(
                    "No trip yet",
                    systemImage: "suitcase",
                    description: Text("Create a trip in the Itinerary tab first.")
                )
            case .failed(let message):
                ContentUnavailableView(
                    "Couldn't load your trip",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .task(id: reloadOn) {
            do {
                phase = .loaded(try await trips.fetchCurrentTrip())
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }
}
