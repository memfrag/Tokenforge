//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// View modifier that overlays a yellow emphasis badge (1–5) on a view
/// when the Preview pane's emphasis-overlay toggle is on.
///
/// Reads the resolved tokens from `\.resolvedTokens` and looks up the
/// level via `hierarchy.typeEmphasis` for the supplied semantic type style
/// name. If the spec doesn't define an emphasis mapping for that style,
/// the badge silently doesn't render — same fail-quiet behavior as the
/// original private helper inside `PaymentDetailsSample`.
///
/// Used by all four built-in samples (Payment Details, List, Settings,
/// Empty State) so the badge styling stays consistent across them.
///
struct EmphasisBadge: ViewModifier {

    let typeStyleName: String
    let visible: Bool

    @Environment(\.resolvedTokens) private var tokens

    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing) {
            if visible, let level = tokens?.emphasisLevel(for: typeStyleName) {
                Text("\(level)")
                    .font(.system(size: 9, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.black)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.yellow))
                    .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 0.5))
                    .offset(x: 12, y: -4)
            }
        }
    }
}

extension View {
    /// Wraps `self` with the Preview-pane emphasis badge overlay. The badge
    /// is only rendered when `visible == true` and the spec has a
    /// `hierarchy.typeEmphasis` mapping for `typeStyleName`.
    func emphasisBadge(_ typeStyleName: String, visible: Bool) -> some View {
        modifier(EmphasisBadge(typeStyleName: typeStyleName, visible: visible))
    }
}
