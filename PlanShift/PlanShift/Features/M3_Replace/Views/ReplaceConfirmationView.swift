// Module: M3 – placeholder for M3-01 Replace Confirmation.

import SwiftUI

struct ReplaceConfirmationView: View {
    let original: ItineraryActivity
    let alternative: Place
    /// Set when the alternative is an "Original plan" backup.
    var restoring: ItineraryActivity?

    @Environment(AppRouter.self) private var router
    @Environment(ReplaceViewModel.self) private var viewModel

    var body: some View {
        ReplaceConfirmationContent(
            original: original,
            alternative: alternative,
            viewModel: viewModel,
            restoring: restoring,
            onCancel: {
                router.dismissSheet()
            },
            onConfirmed: {
                router.didReplaceActivity()
            }
        )
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.dismissSuccess()
            viewModel.clearError()
            router.showsUpdatedItineraryBanner = false
        }
    }
}
