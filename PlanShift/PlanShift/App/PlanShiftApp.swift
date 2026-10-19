// Module: Shared – app entry point.

import SwiftUI

@main
@MainActor
struct PlanShiftApp: App {
    @State private var router = AppRouter()

    private let persistence: Result<PersistenceController, Error>

    init() {
        do {
            persistence = .success(try PersistenceController())
        } catch {
            persistence = .failure(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch persistence {
            case .success(let persistence):
                RootView(persistence: persistence)
                    .environment(router)

            case .failure:
                ContentUnavailableView {
                    Label(
                        "Unable to Open PlanShift",
                        systemImage: "exclamationmark.triangle"
                    )
                } description: {
                    Text(
                        "The local database could not be loaded. Please restart the app."
                    )
                }
            }
        }
    }
}
