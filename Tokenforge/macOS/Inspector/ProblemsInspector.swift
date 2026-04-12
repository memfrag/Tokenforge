//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// The Problems list shown inside the right-hand inspector's Problems tab.
///
/// Grouped by severity (errors first, then warnings), each item renders an
/// Xcode-style severity glyph, a bold title, the offending token or path in
/// SF Mono, and a breadcrumb of the containing pane/section.
///
struct ProblemsInspector: View {

    let problems: [Problem]
    let summary: ProblemSummary

    private var errors: [Problem] { problems.filter { $0.severity == .error } }
    private var warnings: [Problem] { problems.filter { $0.severity == .warning } }

    var body: some View {
        if problems.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if !errors.isEmpty {
                        group(title: "Errors", count: errors.count, items: errors)
                    }
                    if !warnings.isEmpty {
                        group(title: "Warnings", count: warnings.count, items: warnings)
                    }
                    gateFooter
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.green)
            Text("No problems")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
            Text("The current spec validates cleanly.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Group

    @ViewBuilder
    private func group(title: String, count: Int, items: [Problem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)
                Text("· \(count)")
                    .font(.system(size: 10, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)

            ForEach(items) { problem in
                ProblemRow(problem: problem)
                if problem.id != items.last?.id {
                    Divider()
                        .padding(.leading, 42)
                        .opacity(0.35)
                }
            }
        }
    }

    // MARK: - Export-gate footer

    private var gateFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider().opacity(0.4)
            Text("Export blocks on any issue.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
            Text("Resolve all items above before running Export All.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(14)
    }
}

// MARK: - Row

private struct ProblemRow: View {

    let problem: Problem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            severityBadge
            VStack(alignment: .leading, spacing: 3) {
                Text(problem.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                if let detail = problem.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .lineLimit(2)
                }
                Text(breadcrumbLine)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }

    private var breadcrumbLine: String {
        problem.pane.label + " · " + problem.breadcrumb
    }

    @ViewBuilder
    private var severityBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(badgeBackground)
                .frame(width: 18, height: 18)
            Image(systemName: badgeGlyph)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(badgeForeground)
        }
    }

    private var badgeGlyph: String {
        switch problem.severity {
        case .error: return "xmark"
        case .warning: return "exclamationmark"
        }
    }

    private var badgeBackground: Color {
        switch problem.severity {
        case .error: return Color.red.opacity(0.14)
        case .warning: return Color.orange.opacity(0.16)
        }
    }

    private var badgeForeground: Color {
        switch problem.severity {
        case .error: return Color.red
        case .warning: return Color.orange
        }
    }
}
