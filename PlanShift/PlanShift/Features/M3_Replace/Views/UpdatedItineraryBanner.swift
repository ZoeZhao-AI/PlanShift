// Module: M3 – M3-02 Updated Itinerary Banner, shown as a temporary toast.

import SwiftUI
import UIKit

struct UpdatedItineraryBanner: View {
    private static let visibleDuration: Duration = .seconds(6)

    @Environment(AppRouter.self) private var router
    @Environment(ReplaceViewModel.self) private var viewModel

    var body: some View {
        UpdatedItineraryBannerContent(
            viewModel: viewModel,
            onUndone: hide,
            onClose: hide
        )
        .task(id: viewModel.replacementName) {
            await hideAfterDelay()
        }
    }

    /// Hides the toast after a few seconds. With VoiceOver running it stays until closed,
    /// so there is time to reach Undo. It also stays while an undo is running or its error is shown.
    private func hideAfterDelay() async {
        guard !UIAccessibility.isVoiceOverRunning else { return }
        do {
            try await Task.sleep(for: Self.visibleDuration)
        } catch {
            return
        }
        guard !viewModel.isProcessing, viewModel.errorMessage == nil else { return }
        hide()
    }

    private func hide() {
        withAnimation(.easeOut(duration: 0.3)) {
            router.showsUpdatedItineraryBanner = false
        }
    }
}
