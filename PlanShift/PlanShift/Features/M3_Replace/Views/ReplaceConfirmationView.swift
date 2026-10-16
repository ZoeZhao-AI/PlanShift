// Module: M3 – placeholder for M3-01 Replace Confirmation.

import SwiftUI

struct ReplaceConfirmationView: View {
    let original: ItineraryActivity
    let alternative: Place

    @Environment(AppRouter.self) private var router
    @Environment(ReplaceViewModel.self) private var viewModel

    var body: some View {
        ReplaceConfirmationContent(
            original: original,
            alternative: alternative,
            viewModel: viewModel,
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
