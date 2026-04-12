//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct CardComponentEditor: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var spec: CardSpec { document.spec.components.card }

    private var colors: [PrimitiveReferencePicker.Candidate] {
        ComponentCandidates.colors(document.spec)
    }
    private var radii: [PrimitiveReferencePicker.Candidate] {
        ComponentCandidates.radiusAliases(document.spec)
    }
    private var spacings: [PrimitiveReferencePicker.Candidate] {
        ComponentCandidates.spacingAliases(document.spec)
    }

    var body: some View {
        containerSection
        Divider().opacity(0.35)
        slotsSection
        Divider().opacity(0.35)
        ComponentRulesList(
            rules: spec.rules,
            onAdd: addRule,
            onDelete: deleteRule,
            onKindChange: updateRuleKind,
            onTextCommit: updateRuleText
        )
    }

    private var containerSection: some View {
        SectionCard(title: "Container") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                ComponentFieldRow(
                    label: "background",
                    reference: spec.container.background,
                    candidates: colors,
                    referenceBuilder: { TokenRef.semantic("color", $0) },
                    onCommit: { ref in update { $0.container.background = ref } }
                )
                ComponentFieldRow(
                    label: "radius",
                    reference: spec.container.radius,
                    candidates: radii,
                    referenceBuilder: { TokenRef.semantic("radius", $0) },
                    onCommit: { ref in update { $0.container.radius = ref } }
                )
                ComponentFieldRow(
                    label: "padding",
                    reference: spec.container.padding,
                    candidates: spacings,
                    referenceBuilder: { TokenRef.semantic("spacing", $0) },
                    onCommit: { ref in update { $0.container.padding = ref } }
                )
                OptionalComponentFieldRow(
                    label: "border",
                    reference: spec.container.borderColor,
                    candidates: colors,
                    referenceBuilder: { TokenRef.semantic("color", $0) },
                    onCommit: { ref in update { $0.container.borderColor = ref } }
                )
            }
        }
    }

    private var slotsSection: some View {
        SectionCard(title: "Allowed slots", aside: "\(spec.allowedSlots.count) slots") {
            Button {
                addSlot()
            } label: {
                Label("Add Slot", systemImage: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.accentColor)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(spec.allowedSlots.enumerated()), id: \.offset) { index, slot in
                    HStack(spacing: 10) {
                        Text("\(index + 1).")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .frame(width: 22, alignment: .trailing)
                        CommitOnDefocusTextField(
                            placeholder: "slot",
                            source: slot,
                            font: .system(size: 12, design: .monospaced)
                        ) { new in
                            updateSlot(index: index, new: new)
                        }
                        .frame(maxWidth: 220, alignment: .leading)
                        Spacer(minLength: 0)
                        Button {
                            removeSlot(index: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 5)
                    if index < spec.allowedSlots.count - 1 {
                        Divider().opacity(0.4)
                    }
                }
                if spec.allowedSlots.isEmpty {
                    Text("No slots defined.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - Mutations

    private func update(_ apply: (inout CardSpec) -> Void) {
        document.edit(actionName: "Edit Card", undoManager: undoManager) { spec in
            apply(&spec.components.card)
        }
    }

    private func addSlot() {
        update { $0.allowedSlots.append("new-slot") }
    }

    private func removeSlot(index: Int) {
        update { draft in
            if index < draft.allowedSlots.count {
                draft.allowedSlots.remove(at: index)
            }
        }
    }

    private func updateSlot(index: Int, new: String) {
        update { draft in
            if index < draft.allowedSlots.count {
                draft.allowedSlots[index] = new
            }
        }
    }

    private func addRule() {
        update { $0.rules.append(ComponentRule(kind: .text, text: "New rule")) }
    }

    private func deleteRule(_ id: UUID) {
        update { $0.rules.removeAll { $0.id == id } }
    }

    private func updateRuleKind(_ id: UUID, _ kind: HierarchyRuleKind) {
        update { draft in
            if let index = draft.rules.firstIndex(where: { $0.id == id }) {
                draft.rules[index].kind = kind
            }
        }
    }

    private func updateRuleText(_ id: UUID, _ text: String) {
        update { draft in
            if let index = draft.rules.firstIndex(where: { $0.id == id }) {
                draft.rules[index].text = text
            }
        }
    }
}
