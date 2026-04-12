//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Compact footer pinned to the bottom of the sidebar. Surfaces at-a-glance
/// metadata about the current document — name, version, schema version,
/// and author — so the author can confirm which spec they're editing
/// without scrolling back up. Replaces the boilerplate placeholder.
///
struct SidebarFooter: View {

    let meta: SpecMeta
    let schemaVersion: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "hexagon.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)
                Text(displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            HStack(spacing: 4) {
                Text("v\(meta.version)")
                    .font(.system(size: 10, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Text("·")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text("schema \(schemaVersion)")
                    .font(.system(size: 10, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
                if !meta.author.isEmpty {
                    Text("·")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text(meta.author)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .top) {
            Rectangle()
                .fill(.separator)
                .frame(height: 0.5)
        }
    }

    private var displayName: String {
        meta.name.isEmpty ? "Untitled" : meta.name
    }
}

#Preview {
    SidebarFooter(
        meta: SpecMeta(
            name: "Acme Design System",
            version: "0.1.0",
            summary: "",
            author: "Martin Johannesson"
        ),
        schemaVersion: 1
    )
    .frame(width: 224)
}
