//
//  M1UseCaseTests.swift
//  PlanShiftTests
//
//  Created by Tianqi Li's Macbook pro on 15/10/2026.
//

import Foundation
import XCTest
@testable import PlanShift

actor MockTripRepository: TripRepository {

    private var currentTrip: Trip?

    func fetchCurrentTrip() async throws -> Trip? {
        return currentTrip
    }

    func createTrip(_ trip: Trip) async throws {
        currentTrip = trip
    }

    func updateTrip(_ trip: Trip) async throws {
        currentTrip = trip
    }
}

// Mock repository for M1 activity tests.
actor M1MockActivityRepository: ActivityRepository {

    private var activities: [ItineraryActivity] = []

    func fetchActivities(
        tripId: UUID
    ) async throws -> [ItineraryActivity] {
        return activities
            .filter { $0.tripId == tripId }
            .sorted { $0.startTime < $1.startTime }
    }

    func fetchActivities(
        on date: Date
    ) async throws -> [ItineraryActivity] {
        return activities
            .filter {
                Calendar.current.isDate(
                    $0.date,
                    inSameDayAs: date
                )
            }
            .sorted { $0.startTime < $1.startTime }
    }

    func add(
        _ activity: ItineraryActivity
    ) async throws {
        activities.append(activity)
    }

    func update(
        _ activity: ItineraryActivity
    ) async throws {
        guard let index = activities.firstIndex(
            where: { $0.id == activity.id }
        ) else {
            throw DomainError.activityNotFound
        }

        activities[index] = activity
    }

    func delete(id: UUID) async throws {
        guard let index = activities.firstIndex(
            where: { $0.id == id }
        ) else {
            throw DomainError.activityNotFound
        }

        activities.remove(at: index)
    }

    func fetchNextUpcoming(
        after date: Date
    ) async throws -> ItineraryActivity? {
        return activities
            .filter { $0.startTime > date }
            .min { $0.startTime < $1.startTime }
    }
}

final class M1UseCaseTests: XCTestCase {

    func testCreateTrip() async throws {

        let repository = MockTripRepository()

        let useCase = CreateTripUseCase(
            repository: repository
        )

        let startDate = Date()
        let endDate = Calendar.current.date(
            byAdding: .day,
            value: 2,
            to: startDate
        )!

        let trip = try await useCase.execute(
            name: "Sydney Weekend",
            startDate: startDate,
            endDate: endDate
        )

        XCTAssertEqual(trip.name, "Sydney Weekend")

        let savedTrip = try await repository.fetchCurrentTrip()

        XCTAssertEqual(savedTrip?.id, trip.id)
    }
    
    func testCreateTripEmptyName() async throws {

        let repository = MockTripRepository()
        let useCase = CreateTripUseCase(
            repository: repository
        )

        let startDate = Date()
        let endDate = startDate

        do {
            _ = try await useCase.execute(
                name: "   ",
                startDate: startDate,
                endDate: endDate
            )

            XCTFail("Expected emptyName error")

        } catch DomainError.emptyName {
            // Expected error

        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let savedTrip = try await repository.fetchCurrentTrip()
        XCTAssertNil(savedTrip)
    }
    
    func testCreateTripInvalidDates() async throws {

        let repository = MockTripRepository()

        let useCase = CreateTripUseCase(
            repository: repository
        )

        let startDate = Date()

        let endDate = Calendar.current.date(
            byAdding: .day,
            value: -2,
            to: startDate
        )!

        do {
            _ = try await useCase.execute(
                name: "Sydney Weekend",
                startDate: startDate,
                endDate: endDate
            )

            XCTFail("Expected invalidTripDates error")

        } catch DomainError.invalidTripDates {
            // Expected error

        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let savedTrip = try await repository.fetchCurrentTrip()
        XCTAssertNil(savedTrip)
    }
    
    func testAddActivity() async throws {

        let repository = M1MockActivityRepository()

        let useCase = AddActivityUseCase(
            repository: repository
        )

        let tripId = UUID()

        let startTime = Calendar.current.date(
            bySettingHour: 10,
            minute: 0,
            second: 0,
            of: Date()
        )!

        let endTime = startTime.addingTimeInterval(60 * 60)

        let activity = ItineraryActivity(
            tripId: tripId,
            name: "Visit Sydney Opera House",
            date: startTime,
            startTime: startTime,
            endTime: endTime,
            locationName: "Sydney Opera House",
            latitude: -33.8568,
            longitude: 151.2153,
            setting: .indoor,
            estimatedCost: Decimal(50)
        )

        try await useCase.execute(activity: activity)

        let savedActivities = try await repository.fetchActivities(
            tripId: tripId
        )

        XCTAssertEqual(savedActivities.count, 1)
        XCTAssertEqual(savedActivities.first?.id, activity.id)
        XCTAssertEqual(
            savedActivities.first?.name,
            "Visit Sydney Opera House"
        )
    }
    
    
    func testAddActivityTimeConflict() async throws {

        let repository = M1MockActivityRepository()

        let useCase = AddActivityUseCase(
            repository: repository
        )

        let tripId = UUID()

        let startTime = Calendar.current.date(
            bySettingHour: 10,
            minute: 0,
            second: 0,
            of: Date()
        )!

        let firstActivity = ItineraryActivity(
            tripId: tripId,
            name: "Sydney Opera House",
            date: startTime,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(3600),
            locationName: "Sydney Opera House",
            latitude: -33.8568,
            longitude: 151.2153,
            setting: .indoor,
            estimatedCost: Decimal(50)
        )

        try await repository.add(firstActivity)

        let secondStart = startTime.addingTimeInterval(1800)

        let secondActivity = ItineraryActivity(
            tripId: tripId,
            name: "Taronga Zoo",
            date: secondStart,
            startTime: secondStart,
            endTime: secondStart.addingTimeInterval(3600),
            locationName: "Taronga Zoo",
            latitude: -33.8430,
            longitude: 151.2410,
            setting: .outdoor,
            estimatedCost: Decimal(45)
        )

        do {
            try await useCase.execute(activity: secondActivity)

            XCTFail("Expected timeConflict error")

        } catch DomainError.timeConflict {
            // Expected error

        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let savedActivities = try await repository.fetchActivities(
            tripId: tripId
        )

        XCTAssertEqual(savedActivities.count, 1)
        XCTAssertEqual(savedActivities.first?.id, firstActivity.id)
    }

    
    func testAddActivityInvalidTime() async throws {

        let repository = M1MockActivityRepository()

        let useCase = AddActivityUseCase(
            repository: repository
        )

        let tripId = UUID()
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(-3600)

        let activity = ItineraryActivity(
            tripId: tripId,
            name: "Sydney Opera House",
            date: startTime,
            startTime: startTime,
            endTime: endTime,
            locationName: "Sydney Opera House",
            latitude: -33.8568,
            longitude: 151.2153,
            setting: .indoor,
            estimatedCost: Decimal(50)
        )

        do {
            try await useCase.execute(activity: activity)

            XCTFail("Expected invalidTimeRange error")

        } catch DomainError.invalidTimeRange {
            // Expected error

        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let savedActivities = try await repository.fetchActivities(
            tripId: tripId
        )

        XCTAssertTrue(savedActivities.isEmpty)
    }

    
    func testUpdateActivity() async throws {

        let repository = M1MockActivityRepository()

        let useCase = UpdateActivityUseCase(
            repository: repository
        )

        let tripId = UUID()

        let startTime = Calendar.current.date(
            bySettingHour: 10,
            minute: 0,
            second: 0,
            of: Date()
        )!

        let activity = ItineraryActivity(
            tripId: tripId,
            name: "Sydney Opera House",
            date: startTime,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(3600),
            locationName: "Sydney Opera House",
            latitude: -33.8568,
            longitude: 151.2153,
            setting: .indoor,
            estimatedCost: Decimal(50)
        )

        try await repository.add(activity)

        var updatedActivity = activity
        updatedActivity.name = "Visit Sydney Opera House"

        try await useCase.execute(
            activity: updatedActivity
        )

        let savedActivities = try await repository.fetchActivities(
            tripId: tripId
        )

        XCTAssertEqual(savedActivities.count, 1)
        XCTAssertEqual(savedActivities.first?.id, activity.id)
        XCTAssertEqual(
            savedActivities.first?.name,
            "Visit Sydney Opera House"
        )
    }

    
    func testUpdateActivityTimeConflict() async throws {

        let repository = M1MockActivityRepository()

        let useCase = UpdateActivityUseCase(
            repository: repository
        )

        let tripId = UUID()

        let startTime = Calendar.current.date(
            bySettingHour: 10,
            minute: 0,
            second: 0,
            of: Date()
        )!

        let firstActivity = ItineraryActivity(
            tripId: tripId,
            name: "Sydney Opera House",
            date: startTime,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(3600),
            locationName: "Sydney Opera House",
            latitude: -33.8568,
            longitude: 151.2153,
            setting: .indoor,
            estimatedCost: Decimal(50)
        )

        let secondStart = startTime.addingTimeInterval(7200)

        let secondActivity = ItineraryActivity(
            tripId: tripId,
            name: "Taronga Zoo",
            date: secondStart,
            startTime: secondStart,
            endTime: secondStart.addingTimeInterval(3600),
            locationName: "Taronga Zoo",
            latitude: -33.8430,
            longitude: 151.2410,
            setting: .outdoor,
            estimatedCost: Decimal(45)
        )

        try await repository.add(firstActivity)
        try await repository.add(secondActivity)

        var updatedActivity = firstActivity

        updatedActivity.startTime =
            secondStart.addingTimeInterval(1800)

        updatedActivity.endTime =
            updatedActivity.startTime.addingTimeInterval(3600)

        do {
            try await useCase.execute(
                activity: updatedActivity
            )

            XCTFail("Expected timeConflict error")

        } catch DomainError.timeConflict {
            // Expected error

        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let savedActivities = try await repository.fetchActivities(
            tripId: tripId
        )

        XCTAssertEqual(savedActivities.count, 2)

        let savedFirstActivity = savedActivities.first {
            $0.id == firstActivity.id
        }

        XCTAssertEqual(savedFirstActivity?.startTime, startTime)
    }

    
    func testDeleteActivity() async throws {

        let repository = M1MockActivityRepository()

        let useCase = DeleteActivityUseCase(
            repository: repository
        )

        let tripId = UUID()

        let startTime = Calendar.current.date(
            bySettingHour: 10,
            minute: 0,
            second: 0,
            of: Date()
        )!

        let activity = ItineraryActivity(
            tripId: tripId,
            name: "Sydney Opera House",
            date: startTime,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(3600),
            locationName: "Sydney Opera House",
            latitude: -33.8568,
            longitude: 151.2153,
            setting: .indoor,
            estimatedCost: Decimal(50)
        )

        try await repository.add(activity)

        let beforeDelete = try await repository.fetchActivities(
            tripId: tripId
        )

        XCTAssertEqual(beforeDelete.count, 1)

        try await useCase.execute(id: activity.id)

        let afterDelete = try await repository.fetchActivities(
            tripId: tripId
        )

        XCTAssertTrue(afterDelete.isEmpty)
    }

    func testDeleteActivityNotFound() async throws {

        let repository = M1MockActivityRepository()

        let useCase = DeleteActivityUseCase(
            repository: repository
        )

        let unknownId = UUID()

        do {
            try await useCase.execute(id: unknownId)

            XCTFail("Expected activityNotFound error")

        } catch DomainError.activityNotFound {
            // Expected error

        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    
    private func makeTestActivity(
        tripId: UUID,
        name: String,
        hour: Int
    ) -> ItineraryActivity {

        let startTime = Calendar.current.date(
            bySettingHour: hour,
            minute: 0,
            second: 0,
            of: Date()
        )!

        return ItineraryActivity(
            tripId: tripId,
            name: name,
            date: startTime,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(3600),
            locationName: name,
            latitude: -33.8568,
            longitude: 151.2153,
            setting: .indoor,
            estimatedCost: Decimal(20)
        )
    }

    func testFetchItinerary() async throws {

        let repository = M1MockActivityRepository()
        let useCase = FetchItineraryUseCase(
            repository: repository
        )

        let tripId = UUID()

        let morning = makeTestActivity(
            tripId: tripId,
            name: "Breakfast",
            hour: 9
        )

        let afternoon = makeTestActivity(
            tripId: tripId,
            name: "Sydney Opera House",
            hour: 14
        )

        try await repository.add(afternoon)
        try await repository.add(morning)

        let activities = try await useCase.execute(
            tripId: tripId
        )

        XCTAssertEqual(activities.count, 2)
        XCTAssertEqual(activities[0].id, morning.id)
        XCTAssertEqual(activities[1].id, afternoon.id)
    }

    func testFetchItineraryByTrip() async throws {

        let repository = M1MockActivityRepository()
        let useCase = FetchItineraryUseCase(
            repository: repository
        )

        let firstTripId = UUID()
        let secondTripId = UUID()

        let firstActivity = makeTestActivity(
            tripId: firstTripId,
            name: "Sydney Opera House",
            hour: 10
        )

        let secondActivity = makeTestActivity(
            tripId: secondTripId,
            name: "Taronga Zoo",
            hour: 12
        )

        try await repository.add(firstActivity)
        try await repository.add(secondActivity)

        let activities = try await useCase.execute(
            tripId: firstTripId
        )

        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(activities.first?.id, firstActivity.id)
    }

}
