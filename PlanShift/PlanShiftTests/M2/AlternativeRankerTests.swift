//
//  AlternativeRankerTests.swift
//  PlanShiftTests
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 tests – ranking rules (UT-03, UT-04, UT-05 plus edge cases).

import XCTest
@testable import PlanShift

final class AlternativeRankerTests: XCTestCase {
    private typealias F = M2Fixtures

    private func rank(
        _ places: [Place],
        disruption: Disruption = .attractionClosed,
        filters: PreferenceFilters = F.open,
        origin: ResolvedOrigin = F.plannedOrigin,
        activity: ItineraryActivity = F.activity()
    ) throws -> [RankedAlternative] {
        try F.ranker.rank(places: places, activity: activity, disruption: disruption, filters: filters, origin: origin)
    }

    // UT-03
    func testRainyDisruptionPrefersIndoor() throws {
        let outdoor = F.place("Aaa Outdoor Garden", setting: .outdoor)
        let indoor = F.place("Zzz Indoor Museum", setting: .indoor)
        let result = try rank([outdoor, indoor], disruption: .rainyWeather)
        XCTAssertEqual(result.first?.place.id, indoor.id, "indoor must beat an otherwise identical outdoor place, even against the alphabet")
    }

    // UT-04
    func testOverBudgetPlacesAreExcluded() throws {
        let free = F.place("Free Park", cost: 0)
        let cheap = F.place("Cheap Garden", cost: 12)
        let pricey = F.place("Pricey Zoo", cost: 35)

        var filters = F.open
        filters.budget = .under30
        let under30 = try rank([free, cheap, pricey], filters: filters)
        XCTAssertEqual(Set(under30.map(\.place.id)), [free.id, cheap.id])

        filters.budget = .free
        let onlyFree = try rank([free, cheap, pricey], filters: filters)
        XCTAssertEqual(onlyFree.map(\.place.id), [free.id])
    }

    // UT-05
    func testNoMatchesThrowsNoMatchingAlternatives() {
        var filters = F.open
        filters.budget = .free
        XCTAssertThrowsError(try rank([F.place("Paid", cost: 20)], filters: filters)) {
            XCTAssertEqual($0 as? DomainError, .noMatchingAlternatives)
        }
        XCTAssertThrowsError(try rank([])) {
            XCTAssertEqual($0 as? DomainError, .noMatchingAlternatives)
        }
    }

    func testDistanceFilterUsesLimitsAndFiveKmPlusIsUnlimited() throws {
        let near = F.place("Near", kmNorth: 0.8)
        let mid = F.place("Mid", kmNorth: 2.5)
        let far = F.place("Far", kmNorth: 8)

        var filters = F.open
        filters.maxDistance = .oneKm
        XCTAssertEqual(try rank([near, mid, far], filters: filters).map(\.place.id), [near.id])
        filters.maxDistance = .threeKm
        XCTAssertEqual(Set(try rank([near, mid, far], filters: filters).map(\.place.id)), [near.id, mid.id])
        filters.maxDistance = .fiveKmPlus
        XCTAssertEqual(try rank([near, mid, far], filters: filters).count, 3)
    }

    func testDurationBucketBoundaries() {
        XCTAssertTrue(DurationOption.underOneHour.allows(minutes: 60))
        XCTAssertFalse(DurationOption.underOneHour.allows(minutes: 61))
        XCTAssertFalse(DurationOption.oneToTwoHours.allows(minutes: 44))
        XCTAssertTrue(DurationOption.oneToTwoHours.allows(minutes: 45))
        XCTAssertTrue(DurationOption.oneToTwoHours.allows(minutes: 61))
        XCTAssertTrue(DurationOption.oneToTwoHours.allows(minutes: 120))
        XCTAssertFalse(DurationOption.oneToTwoHours.allows(minutes: 121))
        XCTAssertTrue(DurationOption.halfDay.allows(minutes: 121))
        XCTAssertFalse(DurationOption.halfDay.allows(minutes: 120))
    }

    func testOneToTwoHoursOverlapsUnderOneHourFrom45To60() {
        for minutes in [45, 50, 60] {
            XCTAssertTrue(DurationOption.underOneHour.allows(minutes: minutes), "\(minutes)")
            XCTAssertTrue(DurationOption.oneToTwoHours.allows(minutes: minutes), "\(minutes)")
        }
        XCTAssertTrue(DurationOption.underOneHour.allows(minutes: 44))
        XCTAssertFalse(DurationOption.oneToTwoHours.allows(minutes: 44))
    }

    func testTransportDelayPrefersNearerPlace() throws {
        let nearer = F.place("Zzz Nearer", kmNorth: 0.3)
        let farther = F.place("Aaa Farther", kmNorth: 2.5)
        let result = try rank([farther, nearer], disruption: .transportDelay)
        XCTAssertEqual(result.map(\.place.id), [nearer.id, farther.id])
        XCTAssertTrue(result[0].reasons.contains(.closeBy))
    }

    func testRunningOutOfTimePrefersShorterVisit() throws {
        // Both inside the same "Under 1 hr" bucket, so only the scoring separates them.
        let short = F.place("Zzz Short", minutes: 30)
        let long = F.place("Aaa Long", minutes: 60)
        var filters = F.open
        filters.duration = .underOneHour
        let result = try rank([long, short], disruption: .runningOutOfTime, filters: filters)
        XCTAssertEqual(result.first?.place.id, short.id)
        XCTAssertTrue(result[0].reasons.contains(.quickVisit))
    }

    func testReturnsAtMostEightWithSequentialRanks() throws {
        let places = (0..<12).map { F.place("Place \($0)", suburb: "Suburb \($0)", kmNorth: 0.2 + Double($0) * 0.1) }
        let result = try rank(places)
        XCTAssertEqual(result.count, 8)
        XCTAssertEqual(result.map(\.rank), Array(1...8))
        XCTAssertEqual(result.map(\.score), result.map(\.score).sorted(by: >), "scores must not increase down the list")
    }

    func testOrderIsDeterministicRegardlessOfInputOrder() throws {
        // Identical in every scored respect; only name/id differ.
        let names = ["Delta", "India", "Alpha", "Golf", "Charlie", "Juliet", "Echo", "Hotel", "Bravo", "Foxtrot"]
        let places = names.map { F.place($0, suburb: $0) }
        let forward = try rank(places).map(\.place.name)
        let reversed = try rank(places.reversed()).map(\.place.name)
        XCTAssertEqual(forward, ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel"])
        XCTAssertEqual(forward, reversed)
    }

    func testDiversityPenaltyPrefersAnotherSuburbForSecondSlot() throws {
        // Two near-equal places in one suburb, a slightly worse one elsewhere.
        let a = F.place("A Museum", suburb: "Sydney", kmNorth: 0.3)
        let b = F.place("B Gallery", suburb: "Sydney", kmNorth: 0.31)
        let c = F.place("C Beach", suburb: "Manly", kmNorth: 0.4)
        let result = try rank([a, b, c])
        XCTAssertEqual(result.prefix(2).map(\.place.id), [a.id, c.id])
    }

    func testOriginalActivityIsExcluded() throws {
        let sameAsOriginal = F.place("Taronga Zoo")
        let other = F.place("Other")
        let result = try rank([sameAsOriginal, other])
        XCTAssertEqual(result.map(\.place.id), [other.id])
    }

    func testPlaceClosedForTheWholeSlotIsExcluded() throws {
        let morningOnly = F.place("Morning Market", open: 8, close: 12) // slot is 13:30–16:30
        let allDay = F.place("All Day Park")
        XCTAssertEqual(try rank([morningOnly, allDay]).map(\.place.id), [allDay.id])
    }

    func testOpenDuringSlotTagOnlyWhenWholeVisitFits() throws {
        let fits = F.place("Fits Museum", minutes: 90, open: 10, close: 18)      // 13:30 + 90 min = 15:00 ≤ 18:00
        let partial = F.place("Partial Museum", minutes: 120, open: 10, close: 15) // 13:30 + 120 min runs past 15:00
        let open24 = F.place("Open Park")                                          // no gated hours
        let result = try rank([fits, partial, open24])
        func tags(_ place: Place) -> [ReasonTag] { result.first { $0.place.id == place.id }!.reasons }
        XCTAssertTrue(tags(fits).contains(.openDuringSlot))
        XCTAssertFalse(tags(partial).contains(.openDuringSlot))
        XCTAssertFalse(tags(open24).contains(.openDuringSlot), "a public open space must never claim verified opening hours")
    }

    func testMissingOriginTurnsOffDistanceFilterAndTags() throws {
        let far = F.place("Far", kmNorth: 9)
        var filters = F.open
        filters.maxDistance = .oneKm
        let result = try rank([far], filters: filters, origin: F.noOrigin)
        XCTAssertEqual(result.count, 1, "no origin → distance filter cannot apply")
        XCTAssertNil(result[0].distanceMeters)
        XCTAssertNil(result[0].walkingMinutes)
        XCTAssertFalse(result[0].reasons.contains { if case .walkingMinutes = $0 { true } else { false } })
    }

    func testWalkingTagIsComputedFromDistanceAndOmittedWhenFar() throws {
        let near = F.place("Near", kmNorth: 1)
        let far = F.place("Far", kmNorth: 4)
        let result = try rank([near, far])
        let nearResult = result.first { $0.place.id == near.id }!
        let farResult = result.first { $0.place.id == far.id }!

        let expected = DistanceEstimator.walkingMinutes(forMeters: nearResult.distanceMeters!)
        XCTAssertEqual(nearResult.walkingMinutes, expected)
        XCTAssertTrue(nearResult.reasons.contains(.walkingMinutes(expected)))
        XCTAssertFalse(farResult.reasons.contains { if case .walkingMinutes = $0 { true } else { false } }, "no 'walk' tag for a 50+ minute walk")
    }

    func testRainyIndoorTagAndBudgetTags() throws {
        var filters = F.open
        filters.budget = .under30
        let result = try rank([F.place("Museum", setting: .indoor, cost: 10)], disruption: .rainyWeather, filters: filters)
        XCTAssertTrue(result[0].reasons.contains(.indoors))
        XCTAssertTrue(result[0].reasons.contains(.withinBudget))

        let freeAny = try rank([F.place("Free Museum", setting: .indoor)], disruption: .attractionClosed)
        XCTAssertTrue(freeAny[0].reasons.contains(.free))
    }

    func testScoreIsTheWeightedSumOfTheComponents() {
        // Rainy weights: .30 .30 .15 .10 .05 .10  ·  c = 1, 1, 0.4, 2/3, 1, 1   →  ≈ 0.8767 (the worked example)
        let c = ComponentScores(disruptionFit: 1, settingFit: 1, distance: 0.4, duration: 2.0 / 3.0, budget: 1, hours: 1)
        XCTAssertEqual(Disruption.rainyWeather.rankingWeights.score(c), 0.30 + 0.30 + 0.15 * 0.4 + 0.10 * (2.0 / 3.0) + 0.05 + 0.10, accuracy: 1e-12)
        // All-ones scores give exactly the sum of the weights, i.e. 1.
        let ones = ComponentScores(disruptionFit: 1, settingFit: 1, distance: 1, duration: 1, budget: 1, hours: 1)
        for disruption in Disruption.allCases { XCTAssertEqual(disruption.rankingWeights.score(ones), 1.0, accuracy: 1e-9) }
        // Subscript reads the right slot.
        XCTAssertEqual(Disruption.transportDelay.rankingWeights[.distance], 0.50)
        XCTAssertEqual(Disruption.runningOutOfTime.rankingWeights[.duration], 0.45)
    }

    func testRankingWeightsSumToOne() {
        for disruption in Disruption.allCases {
            XCTAssertEqual(disruption.rankingWeights.total, 1.0, accuracy: 1e-9, "\(disruption)")
        }
    }
}
