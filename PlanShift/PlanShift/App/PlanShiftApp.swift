// Module: Shared – app entry point.

import SwiftUI

@main
@MainActor
struct PlanShiftApp: App {
    @State private var router = AppRouter()

    @AppStorage("preferences.appearance")
    private var appearanceRawValue = AppearanceOption.automatic.rawValue

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
            Group {
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
            .preferredColorScheme(preferredColorScheme)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        let appearance = AppearanceOption(
            rawValue: appearanceRawValue
        ) ?? .automatic

        switch appearance {
        case .automatic:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
