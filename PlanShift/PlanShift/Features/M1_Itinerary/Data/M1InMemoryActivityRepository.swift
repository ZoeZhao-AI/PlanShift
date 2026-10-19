//
//  M1InMemoryActivityRepository.swift
//  PlanShift
//
//  Created by Tianqi Li's Macbook pro on 19/10/2026.
//


import Foundation

// Temporary in-memory storage for M1 development.

actor M1InMemoryActivityRepository: ActivityRepository {

    static let shared = M1InMemoryActivityRepository()

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
