//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct TextFieldComponentEditor: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var spec: TextFieldSpec { document.spec.components.textField }

    private var colors: [PrimitiveReferencePicker.Candidate] {
        ComponentCandidates.colors(document.spec)
    }
    private var radii: [PrimitiveReferencePicker.Candidate] {
        ComponentCandidates.radiusAliases(document.spec)
    }
    private var spacings: [PrimitiveReferencePicker.Candidate] {
        ComponentCandidates.spacingAliases(document.spec)
    }
    private var typeStyles: [PrimitiveReferencePicker.Candidate] {
        ComponentCandidates.typeStyles(document.spec)
    }

    var body: some View {
        surfaceSection
        Divider().opacity(0.35)
        sizesSection
        Divider().opacity(0.35)
        statesSection
        Divider().opacity(0.35)
        ComponentRulesList(
            rules: spec.rules,
            onAdd: addRule,
            onDelete: deleteRule,
            onKindChange: updateRuleKind,
            onTextCommit: updateRuleText
        )
    }

    private var surfaceSection: some View {
        SectionCard(title: "Surface") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                colorFieldRow("background", \.background)
                colorFieldRow("label color", \.labelColor)
                colorFieldRow("placeholder", \.placeholderColor)
                colorFieldRow("border", \.borderColor)
                colorFieldRow("error", \.errorColor)
                ComponentFieldRow(
                    label: "radius",
                    reference: spec.radius,
                    candidates: radii,
                    referenceBuilder: { TokenRef.semantic("radius", $0) },
                    onCommit: { ref in update { $0.radius = ref } }
                )
            }
        }
    }

    @ViewBuilder
    private func colorFieldRow(_ label: String, _ keyPath: WritableKeyPath<TextFieldSpec, TokenRef>) -> some View {
        ComponentFieldRow(
            label: label,
            reference: spec[keyPath: keyPath],
            candidates: colors,
            referenceBuilder: { TokenRef.semantic("color", $0) },
            onCommit: { ref in update { draft in draft[keyPath: keyPath] = ref } }
        )
    }

    private var sizesSection: some View {
        SectionCard(title: "Sizes") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                sizeEditor(
                    title: "medium",
                    size: spec.sizes.medium,
                    commit: { new in update { $0.sizes.medium = new } }
                )
                Divider().opacity(0.5)
                sizeEditor(
                    title: "large",
                    size: spec.sizes.large,
                    commit: { new in update { $0.sizes.large = new } }
                )
            }
        }
    }

    @ViewBuilder
    private func sizeEditor(
        title: String,
        size: TextFieldSize,
        commit: @escaping (TextFieldSize) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            ComponentNumericFieldRow(
                label: "height",
                value: size.heightPoints,
                onCommit: { new in var draft = size; draft.heightPoints = new; commit(draft) }
            )
            ComponentFieldRow(
                label: "h. padding",
                reference: size.horizontalPadding,
                candidates: spacings,
                referenceBuilder: { TokenRef.semantic("spacing", $0) },
                onCommit: { ref in var draft = size; draft.horizontalPadding = ref; commit(draft) }
            )
            ComponentFieldRow(
                label: "label style",
                reference: size.labelStyle,
                candidates: typeStyles,
                referenceBuilder: { TokenRef.semantic("type", $0) },
                onCommit: { ref in var draft = size; draft.labelStyle = ref; commit(draft) }
            )
        }
    }

    private var statesSection: some View {
        SectionCard(title: "States") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                stateEditor(
                    title: "focused",
                    state: spec.states.focused,
                    commit: { new in update { $0.states.focused = new } }
                )
                Divider().opacity(0.5)
                stateEditor(
                    title: "disabled",
                    state: spec.states.disabled,
                    commit: { new in update { $0.states.disabled = new } }
                )
                Divider().opacity(0.5)
                stateEditor(
                    title: "error",
                    state: spec.states.error,
                    commit: { new in update { $0.states.error = new } }
                )
            }
        }
    }

    @ViewBuilder
    private func stateEditor(
        title: String,
        state: TextFieldStateOverride,
        commit: @escaping (TextFieldStateOverride) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            OptionalComponentFieldRow(
                label: "border",
                reference: state.borderColor,
                candidates: colors,
                referenceBuilder: { TokenRef.semantic("color", $0) },
                onCommit: { ref in var draft = state; draft.borderColor = ref; commit(draft) }
            )
            OptionalComponentFieldRow(
                label: "background",
                reference: state.background,
                candidates: colors,
                referenceBuilder: { TokenRef.semantic("color", $0) },
                onCommit: { ref in var draft = state; draft.background = ref; commit(draft) }
            )
        }
    }

    // MARK: - Mutations

    private func update(_ apply: (inout TextFieldSpec) -> Void) {
        document.edit(actionName: "Edit TextField", undoManager: undoManager) { spec in
            apply(&spec.components.textField)
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
