import XCTest
@testable import PlanShift

final class WidgetActivityLinkTests: XCTestCase {
    private let id = UUID(uuidString: "E0CA19FE-06A3-4C03-9A7B-993BDE638461")!

    func testGeneratedLinkRoundTrips() throws {
        let url = try XCTUnwrap(WidgetActivityLink.url(for: id))
        XCTAssertEqual(url.absoluteString, "planshift://activity/\(id.uuidString)")
        XCTAssertEqual(WidgetActivityLink.activityId(from: url), id)
    }

    func testSchemeHostAndUUIDAreCaseInsensitive() throws {
        let url = try XCTUnwrap(URL(string: "PLANSHIFT://ACTIVITY/\(id.uuidString.lowercased())"))
        XCTAssertEqual(WidgetActivityLink.activityId(from: url), id)
    }

    func testRejectsWrongSchemeHostAndRelativeURLs() throws {
        try assertInvalid([
            "https://activity/\(id)", "planshift://trip/\(id)",
            "planshift:///activity/\(id)", "/activity/\(id)"
        ])
    }

    func testRejectsMissingInvalidAndExtraPathComponents() throws {
        try assertInvalid([
            "planshift://activity", "planshift://activity/",
            "planshift://activity/not-a-uuid", "planshift://activity/\(id)/edit",
            "planshift://activity/\(id)/", "planshift://activity//\(id)",
            "planshift://activity/\(id)%2Fedit"
        ])
    }

    func testRejectsCredentialsPortQueryAndFragment() throws {
        try assertInvalid([
            "planshift://user@activity/\(id)", "planshift://user:password@activity/\(id)",
            "planshift://activity:8080/\(id)", "planshift://activity/\(id)?trip=other",
            "planshift://activity/\(id)#edit", "planshift://activity/\(id)?"
        ])
    }

    private func assertInvalid(_ strings: [String]) throws {
        for string in strings {
            let url = try XCTUnwrap(URL(string: string), string)
            XCTAssertNil(WidgetActivityLink.activityId(from: url), string)
        }
    }
}
