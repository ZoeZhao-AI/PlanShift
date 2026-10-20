import SwiftUI
import XCTest
@testable import PlanShift

/// Captures artifacts for visual review; these are not pixel-diff assertions.
final class LocationAppearanceTests: XCTestCase {
    @MainActor
    func testCapturePermissionStatesInBothAppearancesAndLargeText() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        for status in [LocationAuthorizationStatus.notDetermined, .denied, .restricted] {
            for dark in [false, true] {
                for largeText in [false, true] {
                    let screen = NavigationStack {
                        LocationPrePromptView(location: M5LocationStub(status: status))
                    }
                    .environment(\.dynamicTypeSize, largeText ? .accessibility5 : .large)
                    .preferredColorScheme(dark ? .dark : .light)
                    let host = UIHostingController(rootView: screen)
                    let window = UIWindow(windowScene: scene)
                    window.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
                    window.rootViewController = host
                    window.makeKeyAndVisible()
                    defer {
                        window.isHidden = true
                        window.rootViewController = nil
                    }
                    try await Task.sleep(for: .milliseconds(250))
                    host.view.layoutIfNeeded()
                    let image = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
                        host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
                    }
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "M5-\(status)-\(dark ? "dark" : "light")-\(largeText ? "AX5" : "default")"
                    attachment.lifetime = .keepAlways
                    add(attachment)
                    if largeText, status.isBlocked,
                       let scrollView = scrollView(in: host.view) {
                        let bottom = max(-scrollView.adjustedContentInset.top,
                                         scrollView.contentSize.height - scrollView.bounds.height
                                         + scrollView.adjustedContentInset.bottom)
                        scrollView.setContentOffset(CGPoint(x: 0, y: bottom), animated: false)
                        try await Task.sleep(for: .milliseconds(100))
                        let bottomImage = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
                            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
                        }
                        let bottomAttachment = XCTAttachment(image: bottomImage)
                        bottomAttachment.name = "M5-\(status)-\(dark ? "dark" : "light")-AX5-bottom"
                        bottomAttachment.lifetime = .keepAlways
                        add(bottomAttachment)
                    }
                }
            }
        }
    }

    @MainActor
    private func scrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        return view.subviews.lazy.compactMap { self.scrollView(in: $0) }.first
    }
}
