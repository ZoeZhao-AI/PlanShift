import Foundation

/// Shared link format for the future widget provider and app router integration.
nonisolated enum WidgetActivityLink {
    static func url(for activityId: UUID) -> URL? {
        var components = URLComponents()
        components.scheme = "planshift"
        components.host = "activity"
        components.path = "/\(activityId.uuidString)"
        return components.url
    }

    /// Validates the URL only. The detail screen must still check whether the activity exists.
    static func activityId(from url: URL) -> UUID? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "planshift",
              components.host?.lowercased() == "activity",
              components.user == nil, components.password == nil, components.port == nil,
              components.query == nil, components.fragment == nil else { return nil }

        let path = components.path.split(separator: "/", omittingEmptySubsequences: false)
        guard path.count == 2, path[0].isEmpty else { return nil }
        return UUID(uuidString: String(path[1]))
    }
}
