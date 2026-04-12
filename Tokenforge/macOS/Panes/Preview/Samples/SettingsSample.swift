//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Built-in Settings sample — an iOS-native grouped form for Notifications
/// preferences. Four sections (Allow / Alerts / Style / Danger) with live
/// `Toggle` switches, a segmented picker, and a destructive action row.
///
/// Exercises the widest semantic surface of any sample: text + status
/// colors, border subtle, the full spacing scale, and `card` radius for
/// the grouped section containers.
///
/// Honors the Preview pane's controls strip:
/// - Appearance picker → token resolution flips through `\.resolvedTokens`.
/// - State picker → `.disabled` dims the entire form to 0.4 opacity and
///   sets `.disabled(true)` on every control. Other states render the
///   same as default since a grouped form has no meaningful pressed or
///   selected concept.
/// - Emphasis overlay → tags the navBar title and section headers.
///
struct SettingsSample: View {

    let state: PreviewState
    let showEmphasis: Bool

    @Environment(\.resolvedTokens) private var tokens

    @State private var notificationsEnabled: Bool = true
    @State private var mentionsEnabled: Bool = true
    @State private var reactionsEnabled: Bool = false
    @State private var dmEnabled: Bool = true
    @State private var alertStyle: AlertStyle = .banner

    private enum AlertStyle: String, CaseIterable, Identifiable {
        case banner = "Banner"
        case alert = "Alert"
        case none = "None"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            Divider().background(borderSubtle)
            ScrollView {
                VStack(spacing: sectionGap) {
                    section(title: "ALLOW NOTIFICATIONS") {
                        toggleRow(
                            label: "Enable Notifications",
                            value: $notificationsEnabled,
                            isLast: true
                        )
                    }
                    section(title: "ALERTS") {
                        toggleRow(label: "Mentions", value: $mentionsEnabled, isLast: false)
                        toggleRow(label: "Reactions", value: $reactionsEnabled, isLast: false)
                        toggleRow(label: "Direct Messages", value: $dmEnabled, isLast: true)
                    }
                    section(title: "STYLE") {
                        Picker("", selection: $alertStyle) {
                            ForEach(AlertStyle.allCases) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    section(title: "DANGER") {
                        destructiveRow
                    }
                }
                .padding(.horizontal, screenPadding)
                .padding(.vertical, 18)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .opacity(state == .disabled ? 0.4 : 1)
        .disabled(state == .disabled)
    }

    // MARK: - NavBar

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
            Text("Notifications")
                .font(titleMediumFont)
                .foregroundStyle(textPrimary)
                .emphasisBadge("title-medium", visible: showEmphasis)
            Spacer()
            Color.clear.frame(width: 44)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }

    // MARK: - Section

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(captionFont)
                .foregroundStyle(textTertiary)
                .padding(.leading, 4)
                .emphasisBadge("caption", visible: showEmphasis)
            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                    .fill(backgroundPrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
                    .stroke(borderSubtle, lineWidth: 0.5)
            )
        }
    }

    @ViewBuilder
    private func toggleRow(label: String, value: Binding<Bool>, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(bodyFont)
                    .foregroundStyle(textPrimary)
                Spacer()
                Toggle("", isOn: value)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.regular)
                    .tint(statusSuccess)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            if !isLast {
                Divider()
                    .background(borderSubtle)
                    .padding(.leading, 16)
            }
        }
    }

    private var destructiveRow: some View {
        Button {
            // Interactive preview — no-op.
        } label: {
            HStack {
                Text("Disable All")
                    .font(bodyFont)
                    .foregroundStyle(textError)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Token lookups

    private var backgroundPrimary: Color {
        tokens?.color("background.primary") ?? Palette.magentaPlaceholder
    }

    private var textPrimary: Color {
        tokens?.color("text.primary") ?? Palette.magentaPlaceholder
    }

    private var textTertiary: Color {
        tokens?.color("text.tertiary") ?? Palette.magentaPlaceholder
    }

    private var textError: Color {
        tokens?.color("text.error") ?? Palette.magentaPlaceholder
    }

    private var borderSubtle: Color {
        tokens?.color("border.subtle") ?? Palette.magentaPlaceholder
    }

    private var actionColor: Color {
        tokens?.color("action.primary.bg") ?? Palette.magentaPlaceholder
    }

    private var statusSuccess: Color {
        tokens?.color("status.success") ?? Palette.magentaPlaceholder
    }

    private var titleMediumFont: Font {
        tokens?.textStyle("title-medium")?.font ?? Font.system(size: 17, weight: .semibold)
    }

    private var bodyFont: Font {
        tokens?.textStyle("body")?.font ?? Font.system(size: 15)
    }

    private var captionFont: Font {
        tokens?.textStyle("caption")?.font ?? Font.system(size: 12)
    }

    private var screenPadding: CGFloat {
        tokens?.spacing("screen-padding") ?? 16
    }

    private var sectionGap: CGFloat {
        tokens?.spacing("section-gap") ?? 24
    }

    private var cardRadius: CGFloat {
        tokens?.radius("card") ?? 14
    }
}
