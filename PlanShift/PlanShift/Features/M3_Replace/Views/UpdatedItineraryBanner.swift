// Module: M3 – placeholder for M3-02 Updated Itinerary Banner.

import SwiftUI

struct UpdatedItineraryBanner: View {
    @Environment(AppRouter.self) private var router
    @Environment(ReplaceViewModel.self) private var viewModel

    var body: some View {
        UpdatedItineraryBannerContent(
            viewModel: viewModel,
            onUndone: {
                router.showsUpdatedItineraryBanner = false
            }
        )
    }
}
