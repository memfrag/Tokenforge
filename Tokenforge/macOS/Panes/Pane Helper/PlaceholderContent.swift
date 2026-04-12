//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Temporary placeholder used inside every pane until real editors are implemented.
struct PlaceholderContent: View {

    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
    }
}

#Preview {
    PlaceholderContent(
        title: "Primitives",
        subtitle: "Raw values — color, spacing, radius, typography.",
        systemImage: "square.stack.3d.up"
    )
    .padding()
}
