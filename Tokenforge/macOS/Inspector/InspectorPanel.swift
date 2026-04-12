//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Right-hand inspector for the document window. Three tabs:
///
/// - **Info** — placeholder for per-selection details (Phase 11).
/// - **Problems** — live validation findings from `Validator.validate(_:)`.
///   Grouped by severity, Xcode-style.
/// - **History** — placeholder for undo history browser (future phase).
///
/// The Problems tab is auto-selected when the document has any findings so
/// the author never misses a new issue, but stays manually sticky after
/// that (so moving off it doesn't get force-reverted on every edit).
///
struct InspectorPanel: View {

    @Bindable var document: TokenforgeDocument
    let activePane: SidebarPane

    @State private var selectedTab: Tab = .info
    @State private var hasAutoSwitchedToProblems = false

    private var problems: [Problem] {
        Validator.validate(document.spec)
    }

    private var summary: ProblemSummary {
        ProblemSummary(problems: problems)
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider().opacity(0.4)

            switch selectedTab {
            case .info:
                InfoInspector(document: document, activePane: activePane)
            case .problems:
                ProblemsInspector(problems: problems, summary: summary)
            case .history:
                historyTab
            }
        }
        .onChange(of: summary.errors) { _, newErrors in
            if newErrors > 0, !hasAutoSwitchedToProblems {
                selectedTab = .problems
                hasAutoSwitchedToProblems = true
            }
        }
        .onAppear {
            if summary.errors > 0, !hasAutoSwitchedToProblems {
                selectedTab = .problems
                hasAutoSwitchedToProblems = true
            }
        }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 0)
    }

    @ViewBuilder
    private func tabButton(_ tab: Tab) -> some View {
        let isSelected = tab == selectedTab
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 5) {
                Text(tab.label)
                    .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium))
                if tab == .problems, !summary.isClean {
                    Text("· \(summary.total)")
                        .font(.system(size: 11, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(height: 1.5)
                    .offset(y: 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Placeholder tabs

    private var historyTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.system(size: 13, weight: .semibold))
            Text("Recent edits will appear here.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Tab identity

extension InspectorPanel {
    enum Tab: String, CaseIterable, Identifiable {
        case info
        case problems
        case history

        var id: String { rawValue }
        var label: String {
            switch self {
            case .info: return "Info"
            case .problems: return "Problems"
            case .history: return "History"
            }
        }
    }
}
