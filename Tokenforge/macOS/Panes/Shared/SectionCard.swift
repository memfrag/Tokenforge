//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// A section block inside a pane: uppercase label header with an aside count
/// on the right, then a rounded, hairline-stroked card holding arbitrary
/// content. Mirrors the section blocks in the HTML design exploration.
///
struct SectionCard<Content: View, Trailing: View>: View {

    let title: String
    let aside: String?
    @ViewBuilder let trailing: () -> Trailing
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        aside: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.aside = aside
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                if let aside {
                    Text(aside)
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 8)
                trailing()
            }
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.separator, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
    }
}
