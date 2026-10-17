// Module: M4 – one backup card (M4-01 rows and the top of M4-02): thumbnail, title, tag pills.

import SwiftUI

/// A rounded card for one backup. Only shows what `BackupRow` already contains.
struct BackupRowCard: View {
    let row: BackupRow
    /// Small teal label above the title, e.g. "Backup" on M4-02.
    var badge: String?
    /// The list rows open M4-02, so they show a chevron; the M4-02 card does not.
    var showsChevron = true

    /// Grows with Dynamic Type so the thumbnail stays in proportion with the text.
    @ScaledMetric(relativeTo: .body) private var scaledThumbnailSize: CGFloat = 64
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Capped, so at the largest text sizes the photo does not push the title off the card.
    private var thumbnailSize: CGFloat {
        min(scaledThumbnailSize, 96)
    }

    var body: some View {
        // At accessibility text sizes, stack the photo above the text so the title has the full width.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))

        layout {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                if let badge {
                    Text(badge)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppColors.primary.opacity(0.15), in: Capsule())
                }

                Text(row.title)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                PillFlowLayout(spacing: 6) {
                    if row.isFromReplacedActivity {
                        TagPill(text: "Original plan", systemImage: "arrow.uturn.backward", style: .originalPlan)
                    }
                    ForEach(row.tags, id: \.self) { tag in
                        TagPill(text: tag, systemImage: Self.icon(for: tag), style: Self.style(for: tag))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsChevron, !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(12)
        .frame(minHeight: 44)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        // VoiceOver reads the card as one item, e.g. "Australian Museum, Indoor, Free entry, ~2 hrs".
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var thumbnail: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        if let imageName = row.imageName {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: thumbnailSize, height: thumbnailSize)
                .clipShape(shape)
                .accessibilityHidden(true)
        } else {
            // Replaced activities have no photo, so show a neutral tile instead.
            shape
                .fill(AppColors.textSecondary.opacity(0.15))
                .frame(width: thumbnailSize, height: thumbnailSize)
                .overlay {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .accessibilityHidden(true)
        }
    }

    // MARK: - Tag icons and colours

    /// Picks an SF Symbol from the tag text the view model gives us.
    private static func icon(for tag: String) -> String {
        if tag == ActivitySetting.indoor.title { return "building.columns" }
        if tag == ActivitySetting.outdoor.title { return "sun.max" }
        if tag.hasPrefix("~") { return "clock" }
        return "ticket"
    }

    private static func style(for tag: String) -> TagPill.Style {
        if tag == ActivitySetting.indoor.title { return .indoor }
        if tag == ActivitySetting.outdoor.title { return .outdoor }
        return .neutral
    }
}

/// A small rounded label such as "Indoor" or "~1.5 hrs".
private struct TagPill: View {
    enum Style {
        case indoor, outdoor, neutral, originalPlan
    }

    let text: String
    let systemImage: String
    let style: Style

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
    }

    private var foreground: Color {
        switch style {
        case .indoor: AppColors.indoorForeground
        case .outdoor: AppColors.outdoorForeground
        case .neutral: AppColors.textSecondary
        case .originalPlan: AppColors.coral
        }
    }

    private var background: Color {
        switch style {
        case .indoor: AppColors.indoorBackground
        case .outdoor: AppColors.outdoorBackground
        case .neutral: AppColors.textSecondary.opacity(0.12)
        case .originalPlan: AppColors.coral.opacity(0.15)
        }
    }
}

/// Lays pills out left to right and wraps onto a new line when there is no more room,
/// so nothing is cut off at large text sizes.
private struct PillFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, maxWidth: proposal.width ?? .infinity)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// Splits the pills into lines that fit `maxWidth`.
    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            let widthIfAdded = rows[rows.count - 1].width + (rows[rows.count - 1].indices.isEmpty ? 0 : spacing) + size.width
            if widthIfAdded > maxWidth, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width += (row.indices.isEmpty ? 0 : spacing) + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
            rows[rows.count - 1] = row
        }
        return rows.filter { !$0.indices.isEmpty }
    }
}

#Preview {
    VStack(spacing: 12) {
        BackupRowCard(row: BackupRow(
            id: UUID(), title: "Australian Museum", tags: ["Indoor", "Free entry", "~2 hrs"],
            imageName: "australian-museum", isFromReplacedActivity: false
        ))
        BackupRowCard(row: BackupRow(
            id: UUID(), title: "Taronga Zoo", tags: ["Outdoor", "$51", "~3 hrs"],
            imageName: nil, isFromReplacedActivity: true
        ))
    }
    .padding()
    .background(AppColors.backgroundGradient)
}
