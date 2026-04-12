//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct HierarchyRulesSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var rules: [HierarchyRule] {
        document.spec.hierarchy.rules
    }

    var body: some View {
        SectionCard(title: "Rules", aside: "\(rules.count) rules") {
            Button {
                addRule()
            } label: {
                Label("Add Rule", systemImage: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.accentColor)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(rules) { rule in
                    HierarchyRuleRow(
                        rule: rule,
                        onKindChange: { new in updateKind(id: rule.id, kind: new) },
                        onTextCommit: { new in updateText(id: rule.id, text: new) },
                        onDelete: { delete(id: rule.id) }
                    )
                    if rule.id != rules.last?.id {
                        Divider().opacity(0.4)
                    }
                }
                if rules.isEmpty {
                    Text("No rules defined. Add one with the + button.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - Mutations

    private func addRule() {
        document.edit(actionName: "Add Rule", undoManager: undoManager) { spec in
            spec.hierarchy.rules.append(
                HierarchyRule(kind: .text, text: "New rule")
            )
        }
    }

    private func delete(id: UUID) {
        document.edit(actionName: "Delete Rule", undoManager: undoManager) { spec in
            spec.hierarchy.rules.removeAll { $0.id == id }
        }
    }

    private func updateKind(id: UUID, kind: HierarchyRuleKind) {
        document.edit(actionName: "Edit Rule Kind", undoManager: undoManager) { spec in
            if let index = spec.hierarchy.rules.firstIndex(where: { $0.id == id }) {
                spec.hierarchy.rules[index].kind = kind
            }
        }
    }

    private func updateText(id: UUID, text: String) {
        document.edit(actionName: "Edit Rule Text", undoManager: undoManager) { spec in
            if let index = spec.hierarchy.rules.firstIndex(where: { $0.id == id }) {
                spec.hierarchy.rules[index].text = text
            }
        }
    }
}

// MARK: - Row

private struct HierarchyRuleRow: View {

    let rule: HierarchyRule
    let onKindChange: (HierarchyRuleKind) -> Void
    let onTextCommit: (String) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RuleKindPill(kind: rule.kind, onChange: onKindChange)
                .padding(.top, 2)

            CommitOnDefocusTextField(
                placeholder: "Rule text",
                source: rule.text,
                font: .system(size: 12)
            ) { new in
                onTextCommit(new)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .help("Delete rule")
        }
        .padding(.vertical, 8)
    }
}

/// Pill that shows the current rule kind and opens a menu for switching it.
/// Shared between Hierarchy rules and Component rules via `ComponentRule`.
struct RuleKindPill: View {

    let kind: HierarchyRuleKind
    let onChange: (HierarchyRuleKind) -> Void

    var body: some View {
        Menu {
            ForEach(HierarchyRuleKind.allCases, id: \.self) { candidate in
                Button(candidate.displayName) {
                    if candidate != kind {
                        onChange(candidate)
                    }
                }
            }
        } label: {
            Text(kind.displayName.uppercased())
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(kind.foreground)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(kind.background)
                )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

extension HierarchyRuleKind {
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .action: return "Action"
        case .emphasis: return "Emphasis"
        case .do: return "Do"
        case .dont: return "Don't"
        }
    }

    var foreground: Color {
        switch self {
        case .text: return .blue
        case .action: return .orange
        case .emphasis: return .purple
        case .do: return .green
        case .dont: return .red
        }
    }

    var background: Color {
        foreground.opacity(0.14)
    }
}
