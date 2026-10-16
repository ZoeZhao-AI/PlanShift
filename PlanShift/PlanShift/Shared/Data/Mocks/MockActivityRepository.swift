//
//  MockActivityRepository.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/15.
//

import Foundation

actor MockActivityRepository: ActivityRepository {
    private var activities: [ItineraryActivity]

    init(activities: [ItineraryActivity] = []) {
        self.activities = activities
    }

    func fetchActivities(
        tripId: UUID
    ) async throws -> [ItineraryActivity] {
        activities
            .filter { $0.tripId == tripId }
            .sorted { $0.startTime < $1.startTime }
    }

    func fetchActivities(
        on date: Date
    ) async throws -> [ItineraryActivity] {
        let calendar = Calendar.current

        return activities
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
    }

    func add(_ activity: ItineraryActivity) async throws {
        activities.append(activity)
    }

    func update(_ activity: ItineraryActivity) async throws {
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
        activities
            .filter { $0.startTime > date }
            .min { $0.startTime < $1.startTime }
    }
}
