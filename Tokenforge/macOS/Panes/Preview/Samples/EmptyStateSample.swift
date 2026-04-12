//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Built-in Empty State sample — center-aligned tray icon, title, body
/// copy, and a primary CTA. Exercises the bare-minimum semantic surface:
/// background, text colors, action primary, button radius, and the
/// `stack-gap` semantic spacing.
///
/// Honors the Preview pane's controls strip the same way `PaymentDetailsSample`
/// does — pressed/disabled state picker affects the CTA, the appearance
/// picker switches the background and text via `\.resolvedTokens`, and the
/// emphasis overlay tags the title and body lines.
///
struct EmptyStateSample: View {

    let state: PreviewState
    let showEmphasis: Bool

    @Environment(\.resolvedTokens) private var tokens

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
        }
        .padding(.horizontal, screenPadding)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: stackGap) {
            illustration
            VStack(spacing: 8) {
                Text("No messages yet")
                    .font(titleMediumFont)
                    .foregroundStyle(textPrimary)
                    .multilineTextAlignment(.center)
                    .emphasisBadge("title-medium", visible: showEmphasis)
                Text("When someone sends you a message, it will appear here.")
                    .font(bodyFont)
                    .foregroundStyle(textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
                    .emphasisBadge("body", visible: showEmphasis)
            }
            cta
        }
    }

    private var illustration: some View {
        Image(systemName: "tray")
            .font(.system(size: 64, weight: .regular))
            .foregroundStyle(textTertiary)
    }

    private var cta: some View {
        Button {
            // Interactive preview — no-op.
        } label: {
            Text("Compose new message")
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

    private var textTertiary: Color {
        tokens?.color("text.tertiary") ?? Palette.magentaPlaceholder
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

    private var titleMediumFont: Font {
        tokens?.textStyle("title-medium")?.font ?? Font.system(size: 22, weight: .semibold)
    }

    private var bodyFont: Font {
        tokens?.textStyle("body")?.font ?? Font.system(size: 15)
    }

    private var screenPadding: CGFloat {
        tokens?.spacing("screen-padding") ?? 16
    }

    private var stackGap: CGFloat {
        tokens?.spacing("stack-gap") ?? 24
    }

    private var buttonRadius: CGFloat {
        tokens?.radius("button") ?? 12
    }
}
