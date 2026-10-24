//
//  M2Style.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – styling for the M2 screens: the few brand colours on top of system colours, plus card / button / layout helpers.
//
// Apple HIG: prefer system/semantic colours and materials; use brand colour for tint. So surfaces and body text
// use `.primary`, `.secondary` and materials; only the teal tint and a few warning/label colours live here.
// Additive only: `AppColors.primary` and the other existing tokens are untouched.

import SwiftUI

// MARK: - Colours

extension AppColors {
    /// Fill of prominent buttons. The system draws a white label on it: ≥ 4.5:1 with white (WCAG AA)
    /// and ≥ 3:1 against the page in both appearances.
    static let ctaFill = Color(light: 0x077F71, dark: 0x0A8576)

    /// Brand teal for *text and icons* on the page gradient (≥ 4.5:1). The M2 screens set it as their
    /// tint, so system bar buttons ("Cancel", "Reset", "Back") pick it up. `AppColors.primary` is only ~3:1 there.
    static let actionText = Color(light: 0x066A5E, dark: 0x2CC4B0)

    /// Secondary text on the tinted disruption cards (≥ 5:1 on all four).
    static let secondaryOnTint = Color(light: 0x4A5A6E, dark: 0xA7B3C2)

    /// Warning *text* on the coral banner tint (≥ 5:1).
    static let warningText = Color(light: 0xB42318, dark: 0xFF8A6D)

    /// "Affected activity" label.
    static let affectedForeground = Color(light: 0xA23A22, dark: 0xFFB4A0)
    static let affectedBackground = Color(light: 0xFBD9CF, dark: 0x4A2A22)
}

extension Disruption {
    /// Darker tint for small *text* on a pale tint of the same hue (≥ 5:1). The saturated `tint` stays for icons.
    var textTint: Color {
        switch self {
        case .rainyWeather: Color(light: 0x1D4ED8, dark: 0x60A5FA)
        case .attractionClosed: Color(light: 0xB42318, dark: 0xFF8A6D)
        case .transportDelay: Color(light: 0x92400E, dark: 0xFBBF24)
        case .runningOutOfTime: Color(light: 0x5B21B6, dark: 0xC4B5FD)
        }
    }
}

// MARK: - Card surface, buttons and layout helpers

extension View {
    /// A frosted card: the system material, no custom colours or shadows.
    func cardSurface(cornerRadius: CGFloat = 20) -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// The system prominent button (`.borderedProminent`, large) in the app's teal. One per screen area, for the
    /// primary action. The system draws the label, pressed/disabled states and Dynamic Type behaviour.
    func prominentActionStyle() -> some View {
        buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppColors.ctaFill)
    }

    /// Keeps content at a comfortable reading width on iPad / landscape.
    func readableContentWidth(_ maxWidth: CGFloat = 640) -> some View {
        frame(maxWidth: maxWidth).frame(maxWidth: .infinity)
    }
}

/// A full-width system prominent button (`.borderedProminent`). The label stretches so the *button* fills the row.
struct ProminentButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title).frame(maxWidth: .infinity)
        }
        .prominentActionStyle()
    }
}


/// Lays children out left to right and wraps to a new line when the row is full.
/// Used for reason tags and filter summary chips, so they never clip at large text sizes.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(in: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(in: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(in width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxWidth = max(maxWidth, x - spacing)
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), origins)
    }
}
