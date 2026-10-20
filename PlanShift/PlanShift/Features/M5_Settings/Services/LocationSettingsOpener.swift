import UIKit

@MainActor
enum LocationSettingsOpener {
    static func open() async -> Bool {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return false }
        return await UIApplication.shared.open(url)
    }
}
