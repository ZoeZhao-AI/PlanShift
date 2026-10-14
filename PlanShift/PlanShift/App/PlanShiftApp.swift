// Module: Shared – app entry point.

import SwiftUI

@main
struct PlanShiftApp: App {
    /// Created once and shared with every screen through the Environment.
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
        }
    }
}
