//
//  M2SharedViews.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – small views and styling shared by more than one M2 screen.

import SwiftUI
import UIKit

// MARK: - Disruption tint and icon (M2-01 cards, M2-02 context pill)

extension Disruption {
    /// Icon/text tint of the disruption card and the context chip on M2-02.
    var tint: Color {
        switch self {
        case .rainyWeather: AppColors.rainy
        case .attractionClosed: Color(light: 0xE04F32, dark: 0xFF8A6D) // ≥ 3:1 on the white icon box
        case .transportDelay: AppColors.delay
        case .runningOutOfTime: AppColors.outOfTime
        }
    }
}

/// SF Symbol for a disruption (system symbols, as the HIG recommends).
struct DisruptionIcon: View {
    let disruption: Disruption

    private var symbol: String {
        switch disruption {
        case .rainyWeather: "cloud.rain"
        case .attractionClosed: "door.left.hand.closed"
        case .transportDelay: "tram"
        case .runningOutOfTime: "hourglass"
        }
    }

    var body: some View {
        Image(systemName: symbol).foregroundStyle(disruption.tint)
    }
}

/// Picks an SF Symbol for a place from its name, so cards have artwork without a photo
/// library and without needing a category field in the shared `Place` model.
private enum PlaceSymbol {
    static func name(for placeName: String, setting: ActivitySetting) -> String {
        let n = placeName.lowercased()
        let rules: [([String], String)] = [
            (["zoo"], "pawprint.fill"),
            (["aquarium"], "fish.fill"),
            (["beach", "cove", "bay"], "beach.umbrella.fill"),
            (["museum", "gallery", "library", "arcade", "building"], "building.columns.fill"),
            (["quay", "harbour", "wharf"], "ferry.fill"),
            (["park", "garden", "reserve", "head", "point", "gap", "lookout", "hill"], "tree.fill"),
        ]
        for (keywords, symbol) in rules where keywords.contains(where: n.contains) { return symbol }
        return setting == .indoor ? "building.2.fill" : "sun.max.fill"
    }
}

// MARK: - Place / activity artwork (result cards, activity summary)

/// Remembers which asset names exist, so a re-render does not decode the image just to check.
@MainActor
private enum ImageAvailability {
    private static var cache: [String: Bool] = [:]

    static func exists(_ name: String) -> Bool {
        if let known = cache[name] { return known }
        let found = UIImage(named: name) != nil
        cache[name] = found
        return found
    }
}

/// Shows the place's image from Assets.xcassets if one exists; otherwise a labelled vector
/// stand-in (gradient + SF Symbol). No stock photo is faked. Decorative, so hidden from VoiceOver.
struct PlaceArtworkView: View {
    let name: String
    let setting: ActivitySetting
    var imageName: String?

    var body: some View {
        ZStack {
            if let imageName, ImageAvailability.exists(imageName) {
                Image(imageName).resizable().scaledToFill()
            } else {
                LinearGradient(
                    colors: setting == .indoor
                        ? [AppColors.indoorBackground, AppColors.indoorForeground.opacity(0.35)]
                        : [AppColors.outdoorBackground, AppColors.outdoorForeground.opacity(0.35)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                GeometryReader { proxy in
                    Image(systemName: PlaceSymbol.name(for: name, setting: setting))
                        .font(.system(size: min(proxy.size.width, proxy.size.height) * 0.45))
                        .foregroundStyle(setting == .indoor ? AppColors.indoorForeground : AppColors.outdoorForeground)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
        }
        .clipped()
        // `clipped()` only trims what is drawn. A filled photo still overflows its frame and would swallow
        // taps meant for the views around it, and the artwork has nothing to tap.
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Location-off banner (results and no-results screens)

/// Inline banner (design ID M5-05): location is off, distances use the planned activity instead.
/// The results below stay fully usable. "Open Settings" opens PlanShift's page in iOS Settings.
struct LocationOffBanner: View {
    var openSettings: () -> Void = {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes the button moves under the message instead of squeezing it.
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        layout {
            Image(systemName: "location.slash.fill")
                .foregroundStyle(AppColors.warningText)
                .accessibilityHidden(true)
            Text("Location is off. Distances are based on your planned activity location.")
                .font(.footnote)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Open Settings", action: openSettings)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColors.warningText)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityHint("Opens iOS Settings so you can turn location on")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(AppColors.warningText.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}
