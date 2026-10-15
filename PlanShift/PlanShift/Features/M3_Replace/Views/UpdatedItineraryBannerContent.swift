//
//  UpdatedItineraryBannerContent.swift
//  PlanShift
//
//  Created by Chang Chia ming on 2026/10/16.
//

import SwiftUI

struct UpdatedItineraryBannerContent: View {
    let viewModel: ReplaceViewModel
    let onUndone: () -> Void

    var body: some View {
        if let original = viewModel.originalActivity,
           let replacementName = viewModel.replacementName {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    successIcon
                    message(
                        originalName: original.name,
                        replacementName: replacementName
                    )
                    undoButton
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        successIcon
                        message(
                            originalName: original.name,
                            replacementName: replacementName
                        )
                    }

                    undoButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(16)
            .background(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .accessibilityIdentifier("M3-02")
            .alert(
                "Unable to Undo",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.clearError()
                        }
                    }
                )
            ) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var successIcon: some View {
        Image(systemName: "checkmark")
            .font(.headline)
            .foregroundStyle(AppColors.primary)
            .frame(width: 40, height: 40)
            .background(AppColors.backgroundBottom)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }

    private func message(
        originalName: String,
        replacementName: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Plan updated")
                .font(.headline)

            Text("\(originalName) replaced with \(replacementName)")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(AppColors.backgroundBottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var undoButton: some View {
        Button {
            Task {
                if await viewModel.undo() {
                    onUndone()
                }
            }
        } label: {
            HStack(spacing: 6) {
                if viewModel.isProcessing {
                    ProgressView()
                        .tint(AppColors.backgroundBottom)
                } else {
                    Image(systemName: "arrow.uturn.backward")
                }

                Text(viewModel.isProcessing ? "Undoing…" : "Undo")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppColors.backgroundBottom)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(AppColors.backgroundBottom.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isProcessing)
        .accessibilityLabel("Undo activity replacement")
    }
}
