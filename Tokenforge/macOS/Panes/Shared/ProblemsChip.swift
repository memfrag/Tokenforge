//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Compact Problems chip for the document toolbar. Shows a colored dot per
/// severity and the total count. Tapping opens the inspector (or brings the
/// Problems tab into focus if already open) via the supplied closure.
///
/// When the spec validates cleanly, the chip collapses to a single neutral
/// checkmark so it doesn't clutter the toolbar.
///
struct ProblemsChip: View {

    let summary: ProblemSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if summary.isClean {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                    Text("0")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                } else {
                    if summary.errors > 0 {
                        Circle().fill(Color.red).frame(width: 6, height: 6)
                    }
                    if summary.warnings > 0 {
                        Circle().fill(Color.orange).frame(width: 6, height: 6)
                    }
                    Text("\(summary.total)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 11, weight: .medium))
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help(helpText)
    }

    private var helpText: String {
        if summary.isClean {
            return "No problems"
        }
        var parts: [String] = []
        if summary.errors > 0 {
            parts.append("\(summary.errors) error\(summary.errors == 1 ? "" : "s")")
        }
        if summary.warnings > 0 {
            parts.append("\(summary.warnings) warning\(summary.warnings == 1 ? "" : "s")")
        }
        return parts.joined(separator: ", ")
    }
}
