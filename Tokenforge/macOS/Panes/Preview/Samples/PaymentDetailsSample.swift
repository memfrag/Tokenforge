//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Built-in Payment Details sample — matches the HTML design exploration
/// and exercises most of the semantic token surface (colors, text styles,
/// spacing, radius, emphasis).
///
/// Every lookup falls back to the magenta `Palette.magentaPlaceholder` when
/// a required token can't be resolved, so misses are immediately visible.
///
struct PaymentDetailsSample: View {

    let state: PreviewState
    let showEmphasis: Bool

    @Environment(\.resolvedTokens) private var tokens

    var body: some View {
        VStack(spacing: 0) {
            navBar
                .padding(.top, 4)

            ScrollView {
                VStack(spacing: 18) {
                    hero
                    lineItemsCard
                    actions
                }
                .padding(.horizontal, screenPadding)
                .padding(.vertical, 14)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .foregroundStyle(textPrimary)
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            HStack(spacing: 3) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text("Back")
                    .font(.system(size: 17))
            }
            .foregroundStyle(actionColor)

            Spacer()
            Text("Payment")
                .font(.system(size: 17, weight: .semibold))
            Spacer()
            Color.clear.frame(width: 44)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 4) {
            Text("AMOUNT DUE")
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(textSecondary)
                .emphasisBadge("caption", visible: showEmphasis)
            Text("$2,450.00")
                .font(titleLargeFont)
                .foregroundStyle(textPrimary)
                .monospacedDigit()
                .emphasisBadge("title-large", visible: showEmphasis)
            Text("Due March 15")
                .font(bodyFont)
                .foregroundStyle(textSecondary)
                .emphasisBadge("body", visible: showEmphasis)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Line items card

    private var lineItemsCard: some View {
        VStack(spacing: 0) {
            lineItemRow(icon: "house.fill", title: "Rent", caption: "Monthly", amount: "$1,800.00")
            Divider().background(borderSubtle)
            lineItemRow(icon: "bolt.fill", title: "Utilities", caption: "Feb 14 – Mar 14", amount: "$420.00")
            Divider().background(borderSubtle)
            lineItemRow(icon: "car.fill", title: "Parking", caption: "Residential permit", amount: "$230.00")
        }
        .background(
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .fill(backgroundPrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                .stroke(borderSubtle, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private func lineItemRow(icon: String, title: String, caption: String, amount: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(actionColor)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(actionLabel)
            }
            .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(bodyFont)
                Text(caption)
                    .font(.system(size: 12))
                    .foregroundStyle(textSecondary)
            }
            Spacer()
            Text(amount)
                .font(bodyFont)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 8) {
            Button {
                // Interactive preview — no-op.
            } label: {
                Text("Pay Now")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(actionLabel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: buttonRadius, style: .continuous)
                            .fill(effectiveActionBackground)
                    )
                    .opacity(state == .disabled ? 0.4 : 1)
            }
            .buttonStyle(.plain)
            .disabled(state == .disabled)
            .emphasisBadge("body", visible: showEmphasis)

            Button {
                // Secondary no-op.
            } label: {
                Text("Schedule Payment")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(actionColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: - Token lookups

    private var backgroundPrimary: Color {
        tokens?.color("background.primary") ?? Palette.magentaPlaceholder
    }

    private var textPrimary: Color {
        tokens?.color("text.primary") ?? Palette.magentaPlaceholder
    }

    private var textSecondary: Color {
        tokens?.color("text.secondary") ?? Palette.magentaPlaceholder
    }

    private var borderSubtle: Color {
        tokens?.color("border.subtle") ?? Palette.magentaPlaceholder
    }

    private var actionColor: Color {
        tokens?.color("action.primary.bg") ?? Palette.magentaPlaceholder
    }

    private var actionPressed: Color {
        tokens?.color("action.primary.bg-pressed") ?? actionColor
    }

    private var actionLabel: Color {
        tokens?.color("action.primary.label") ?? Palette.magentaPlaceholder
    }

    private var effectiveActionBackground: Color {
        state == .pressed ? actionPressed : actionColor
    }

    private var titleLargeFont: Font {
        tokens?.textStyle("title-large")?.font ?? Font.system(size: 44, weight: .bold)
    }

    private var bodyFont: Font {
        tokens?.textStyle("body")?.font ?? Font.system(size: 15)
    }

    private var screenPadding: CGFloat {
        tokens?.spacing("screen-padding") ?? 16
    }

    private var cardRadius: CGFloat {
        tokens?.radius("card") ?? 14
    }

    private var buttonRadius: CGFloat {
        tokens?.radius("button") ?? 12
    }
}
