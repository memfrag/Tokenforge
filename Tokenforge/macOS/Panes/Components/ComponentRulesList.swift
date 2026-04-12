//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Rules list editor shared across every component detail view.
///
/// `ComponentRule` has the same `{id, kind, text}` shape as `HierarchyRule`
/// but lives on each component contract, so the row rendering is identical
/// to `HierarchyRulesSection.RuleRow` but the mutations go through closures
/// the component editor supplies.
///
struct ComponentRulesList: View {

    let rules: [ComponentRule]
    let onAdd: () -> Void
    let onDelete: (UUID) -> Void
    let onKindChange: (UUID, HierarchyRuleKind) -> Void
    let onTextCommit: (UUID, String) -> Void

    var body: some View {
        SectionCard(title: "Rules", aside: "\(rules.count) rules") {
            Button {
                onAdd()
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
                    HStack(alignment: .top, spacing: 12) {
                        RuleKindPill(
                            kind: rule.kind,
                            onChange: { new in onKindChange(rule.id, new) }
                        )
                        .padding(.top, 2)

                        CommitOnDefocusTextField(
                            placeholder: "Rule text",
                            source: rule.text,
                            font: .system(size: 12)
                        ) { new in
                            onTextCommit(rule.id, new)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            onDelete(rule.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 8)
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
}
