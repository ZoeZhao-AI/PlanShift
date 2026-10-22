// Module: Shared – design system colour tokens.

import SwiftUI
import UIKit

/// Colour tokens for the "clear skies after rain" style.
/// Every colour switches automatically between Light and Dark Mode.
/// Use these instead of hard-coded colours, e.g. `.foregroundStyle(AppColors.primary)`.
enum AppColors {
    // Background gradient (top-left → bottom-right)
    static let backgroundTop = Color(light: 0xE8F3FF, dark: 0x0B1426)
    static let backgroundBottom = Color(light: 0xE9FBF5, dark: 0x0A2A2A)
    static let backgroundGradient = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Brand
    // Light value darkened from 0x0E9F8E (~3:1) so teal text/icons on the pale page reach WCAG AA (>= 4.5:1).
    static let primary = Color(light: 0x087568, dark: 0x2CC4B0)
    static let coral = Color(light: 0xFF7A59, dark: 0xFF8A6D)

    // Text
    static let textPrimary = Color(light: 0x14213D, dark: 0xF2F5FA)
    static let textSecondary = Color(light: 0x5B6B7F, dark: 0xA7B3C2)

    // Disruptions
    static let rainy = Color(light: 0x3B82F6, dark: 0x60A5FA)
    static let closed = coral
    static let delay = Color(light: 0xD97706, dark: 0xFBBF24)
    static let outOfTime = Color(light: 0x7C3AED, dark: 0xA78BFA)

    // Setting pills (background + text)
    static let indoorBackground = Color(light: 0xE0E7FF, dark: 0x312E81)
    static let indoorForeground = Color(light: 0x3730A3, dark: 0xC7D2FE)
    static let outdoorBackground = Color(light: 0xDCFCE7, dark: 0x14532D)
    static let outdoorForeground = Color(light: 0x166534, dark: 0xBBF7D0)
}

extension Color {
    /// A colour from a hex number, e.g. `Color(hex: 0x0E9F8E)`.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// A colour that uses `light` in Light Mode and `dark` in Dark Mode.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}
