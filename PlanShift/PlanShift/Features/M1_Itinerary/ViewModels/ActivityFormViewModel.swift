//
//  ActivityFormViewModel.swift
//  PlanShift
//
//  Created by Tianqi Li's Macbook pro on 19/10/2026.
//

import Foundation
import Observation

// Module: M1 - Itinerary Management

@MainActor
@Observable
final class ActivityFormViewModel {

    var name = ""
    var date = Date()
    var startTime = Date()
    var endTime = Date().addingTimeInterval(3600)

    var locationName = ""
    var latitude = 0.0
    var longitude = 0.0
    var setting: ActivitySetting = .indoor
    var estimatedCost = 0.0

    /// Name of the place the coordinates came from. Typing a different name clears them,
    /// so a typed name can never keep another place's coordinates.
    private var pickedLocationName: String?

    var isSaving = false
    var errorMessage: String?

    private let tripId: UUID
    private let existingActivity: ItineraryActivity?
    private let addUseCase: AddActivityUseCase
    private let updateUseCase: UpdateActivityUseCase

    /// A location is set once the user picks a place (or the activity being edited already had one).
    var hasLocation: Bool {
        !locationName.isEmpty && !(latitude == 0 && longitude == 0)
    }

    /// Fills the location, coordinates, setting and cost from a place of the bundled dataset.
    func apply(_ place: Place) {
        pickedLocationName = place.name
        locationName = place.name
        latitude = place.latitude
        longitude = place.longitude
        setting = place.setting
        estimatedCost = NSDecimalNumber(decimal: place.cost).doubleValue
    }

    /// Call when the location text changes; drops the coordinates if it no longer matches the picked place.
    func locationTextChanged() {
        guard locationName != pickedLocationName else { return }
        latitude = 0
        longitude = 0
    }

    var isEditing: Bool {
        existingActivity != nil
    }

    init(
        tripId: UUID,
        repository: any ActivityRepository,
        existingActivity: ItineraryActivity? = nil
    ) {
        self.tripId = tripId
        self.existingActivity = existingActivity

        self.addUseCase = AddActivityUseCase(
            repository: repository
        )

        self.updateUseCase = UpdateActivityUseCase(
            repository: repository
        )

        if let activity = existingActivity {
            name = activity.name
            date = activity.date
            startTime = activity.startTime
            endTime = activity.endTime
            locationName = activity.locationName
            pickedLocationName = activity.locationName
            latitude = activity.latitude
            longitude = activity.longitude
            setting = activity.setting
            estimatedCost = NSDecimalNumber(
                decimal: activity.estimatedCost
            ).doubleValue
        }
    }

    func save() async -> Bool {
        guard !isSaving else {
            return false
        }

        guard hasLocation else {
            errorMessage = "Choose a place from the suggestions."
            return false
        }

        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        let activity = ItineraryActivity(
            id: existingActivity?.id ?? UUID(),
            tripId: tripId,
            name: name,
            date: date,
            startTime: startTime,
            endTime: endTime,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            setting: setting,
            estimatedCost: Decimal(estimatedCost)
        )

        do {
            if isEditing {
                try await updateUseCase.execute(
                    activity: activity
                )
            } else {
                try await addUseCase.execute(
                    activity: activity
                )
            }

            return true

        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
