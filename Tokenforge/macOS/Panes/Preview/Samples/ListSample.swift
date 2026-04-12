//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Built-in List sample — an iOS-style Inbox with eight hardcoded
/// messages, monogram avatars, two-line preview text, trailing
/// timestamps, and unread indicators.
///
/// Exercises `listItem`-shaped row layout via the semantic color and
/// typography surface, plus the navBar large-title pattern. Honors the
/// Preview pane's controls strip:
/// - Appearance picker → token resolution flips through `\.resolvedTokens`.
/// - State picker → `.selected` highlights the first row with
///   `background.tertiary`. Other states render the same as default.
/// - Emphasis overlay → tags the navBar title with the `title-large`
///   emphasis level.
///
struct ListSample: View {

    let state: PreviewState
    let showEmphasis: Bool

    @Environment(\.resolvedTokens) private var tokens

    var body: some View {
        VStack(spacing: 0) {
            navBar
            Divider().background(borderSubtle)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        row(for: message, isFirst: index == 0)
                        if index < messages.count - 1 {
                            Divider()
                                .background(borderSubtle)
                                .padding(.leading, 56)
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - NavBar

    private var navBar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Inbox")
                .font(titleLargeFont)
                .foregroundStyle(textPrimary)
                .padding(.horizontal, screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .emphasisBadge("title-large", visible: showEmphasis)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Row

    @ViewBuilder
    private func row(for message: Message, isFirst: Bool) -> some View {
        let isSelected = isFirst && state == .selected
        HStack(alignment: .top, spacing: 12) {
            unreadDot(visible: message.isUnread)
            avatar(for: message)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(message.sender)
                        .font(bodyFont)
                        .fontWeight(message.isUnread ? .semibold : .regular)
                        .foregroundStyle(textPrimary)
                    Spacer(minLength: 6)
                    Text(message.timestamp)
                        .font(captionFont)
                        .foregroundStyle(textTertiary)
                }
                Text(message.preview)
                    .font(captionFont)
                    .foregroundStyle(textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, screenPadding)
        .padding(.vertical, 11)
        .background(isSelected ? backgroundTertiary : Color.clear)
    }

    private func unreadDot(visible: Bool) -> some View {
        Circle()
            .fill(visible ? actionColor : Color.clear)
            .frame(width: 6, height: 6)
            .padding(.top, 6)
    }

    private func avatar(for message: Message) -> some View {
        let tint = avatarTint(for: message.tintIndex)
        return ZStack {
            Circle().fill(tint)
            Text(message.initials)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(actionLabel)
        }
        .frame(width: 38, height: 38)
    }

    private func avatarTint(for index: Int) -> Color {
        let palette: [Color] = [actionColor, statusSuccess, statusWarning]
        guard !palette.isEmpty else {
            return Palette.magentaPlaceholder
        }
        return palette[index % palette.count]
    }

    // MARK: - Hardcoded content

    private struct Message {
        let sender: String
        let initials: String
        let preview: String
        let timestamp: String
        let isUnread: Bool
        let tintIndex: Int
    }

    private var messages: [Message] {
        [
            Message(
                sender: "Anna Jensen",
                initials: "AJ",
                preview: "Lunch tomorrow? I was thinking of trying that new Vietnamese place near the office.",
                timestamp: "2m",
                isUnread: true,
                tintIndex: 0
            ),
            Message(
                sender: "Ben Park",
                initials: "BP",
                preview: "Don't forget the design review meeting at 3:30 today. I'll bring the prototype.",
                timestamp: "1h",
                isUnread: true,
                tintIndex: 1
            ),
            Message(
                sender: "Cal Martinez",
                initials: "CM",
                preview: "Thanks for sending the docs over. I'll take a look this afternoon and circle back.",
                timestamp: "Mon",
                isUnread: false,
                tintIndex: 2
            ),
            Message(
                sender: "Dara Lee",
                initials: "DL",
                preview: "Quick question about the Q2 roadmap — do you have a few minutes to chat?",
                timestamp: "Sun",
                isUnread: false,
                tintIndex: 0
            ),
            Message(
                sender: "Eli Roth",
                initials: "ER",
                preview: "Sharing the slides for tomorrow's all-hands. Let me know if anything looks off.",
                timestamp: "Sun",
                isUnread: false,
                tintIndex: 1
            ),
            Message(
                sender: "Faith Wu",
                initials: "FW",
                preview: "Following up on the contractor invoice — accounting needs the signed PO.",
                timestamp: "Fri",
                isUnread: false,
                tintIndex: 2
            ),
            Message(
                sender: "Gabe Holmes",
                initials: "GH",
                preview: "Welcome aboard! Here's a quick rundown of what we're working on this sprint.",
                timestamp: "Thu",
                isUnread: false,
                tintIndex: 0
            ),
            Message(
                sender: "Hana Okada",
                initials: "HO",
                preview: "Just finished the user research synthesis. Sending over the highlights now.",
                timestamp: "Wed",
                isUnread: false,
                tintIndex: 1
            )
        ]
    }

    // MARK: - Token lookups

    private var textPrimary: Color {
        tokens?.color("text.primary") ?? Palette.magentaPlaceholder
    }

    private var textSecondary: Color {
        tokens?.color("text.secondary") ?? Palette.magentaPlaceholder
    }

    private var textTertiary: Color {
        tokens?.color("text.tertiary") ?? Palette.magentaPlaceholder
    }

    private var borderSubtle: Color {
        tokens?.color("border.subtle") ?? Palette.magentaPlaceholder
    }

    private var backgroundTertiary: Color {
        tokens?.color("background.tertiary") ?? Palette.magentaPlaceholder
    }

    private var actionColor: Color {
        tokens?.color("action.primary.bg") ?? Palette.magentaPlaceholder
    }

    private var actionLabel: Color {
        tokens?.color("action.primary.label") ?? Palette.magentaPlaceholder
    }

    private var statusSuccess: Color {
        tokens?.color("status.success") ?? Palette.magentaPlaceholder
    }

    private var statusWarning: Color {
        tokens?.color("status.warning") ?? Palette.magentaPlaceholder
    }

    private var titleLargeFont: Font {
        tokens?.textStyle("title-large")?.font ?? Font.system(size: 32, weight: .bold)
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
}
