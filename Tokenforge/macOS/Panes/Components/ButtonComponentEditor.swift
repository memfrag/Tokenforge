//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct ButtonComponentEditor: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var spec: ButtonSpec {
        document.spec.components.button
    }

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
        variantsSection
        Divider().opacity(0.35)
        sizesSection
        Divider().opacity(0.35)
        statesSection
        Divider().opacity(0.35)
        rulesSection
    }

    // MARK: - Variants

    @ViewBuilder
    private var variantsSection: some View {
        SectionCard(title: "Variants", aside: "3 defined") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                variantEditor(
                    title: "primary",
                    variant: spec.variants.primary,
                    commit: { new in update { $0.variants.primary = new } }
                )
                Divider().opacity(0.5)
                variantEditor(
                    title: "secondary",
                    variant: spec.variants.secondary,
                    commit: { new in update { $0.variants.secondary = new } }
                )
                Divider().opacity(0.5)
                variantEditor(
                    title: "tertiary",
                    variant: spec.variants.tertiary,
                    commit: { new in update { $0.variants.tertiary = new } }
                )
            }
        }
    }

    @ViewBuilder
    private func variantEditor(
        title: String,
        variant: ButtonVariant,
        commit: @escaping (ButtonVariant) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            ComponentFieldRow(
                label: "background",
                reference: variant.background,
                candidates: colors,
                referenceBuilder: { TokenRef.semantic("color", $0) },
                onCommit: { ref in var new = variant; new.background = ref; commit(new) }
            )
            ComponentFieldRow(
                label: "label",
                reference: variant.label,
                candidates: colors,
                referenceBuilder: { TokenRef.semantic("color", $0) },
                onCommit: { ref in var new = variant; new.label = ref; commit(new) }
            )
            OptionalComponentFieldRow(
                label: "border",
                reference: variant.border,
                candidates: colors,
                referenceBuilder: { TokenRef.semantic("color", $0) },
                onCommit: { ref in var new = variant; new.border = ref; commit(new) }
            )
            ComponentFieldRow(
                label: "radius",
                reference: variant.radius,
                candidates: radii,
                referenceBuilder: { TokenRef.semantic("radius", $0) },
                onCommit: { ref in var new = variant; new.radius = ref; commit(new) }
            )
        }
    }

    // MARK: - Sizes

    @ViewBuilder
    private var sizesSection: some View {
        SectionCard(title: "Sizes", aside: "3 defined") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                sizeEditor(
                    title: "small",
                    size: spec.sizes.small,
                    commit: { new in update { $0.sizes.small = new } }
                )
                Divider().opacity(0.5)
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
        size: ButtonSize,
        commit: @escaping (ButtonSize) -> Void
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

    // MARK: - States

    @ViewBuilder
    private var statesSection: some View {
        SectionCard(title: "States", aside: "3 overrides") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                stateEditor(
                    title: "pressed",
                    state: spec.states.pressed,
                    commit: { new in update { $0.states.pressed = new } }
                )
                Divider().opacity(0.5)
                stateEditor(
                    title: "disabled",
                    state: spec.states.disabled,
                    commit: { new in update { $0.states.disabled = new } }
                )
                Divider().opacity(0.5)
                stateEditor(
                    title: "focus",
                    state: spec.states.focus,
                    commit: { new in update { $0.states.focus = new } }
                )
            }
        }
    }

    @ViewBuilder
    private func stateEditor(
        title: String,
        state: ButtonStateOverride,
        commit: @escaping (ButtonStateOverride) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            OptionalComponentFieldRow(
                label: "background",
                reference: state.background,
                candidates: colors,
                referenceBuilder: { TokenRef.semantic("color", $0) },
                onCommit: { ref in var draft = state; draft.background = ref; commit(draft) }
            )
            OptionalComponentFieldRow(
                label: "label",
                reference: state.label,
                candidates: colors,
                referenceBuilder: { TokenRef.semantic("color", $0) },
                onCommit: { ref in var draft = state; draft.label = ref; commit(draft) }
            )
            OptionalComponentFieldRow(
                label: "focus ring",
                reference: state.focusRing,
                candidates: colors,
                referenceBuilder: { TokenRef.semantic("color", $0) },
                onCommit: { ref in var draft = state; draft.focusRing = ref; commit(draft) }
            )
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("opacity")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 130, alignment: .leading)
                if let opacity = state.opacity {
                    NumericDoubleField(source: opacity, width: 60) { new in
                        var draft = state
                        draft.opacity = new
                        commit(draft)
                    }
                    Button {
                        var draft = state
                        draft.opacity = nil
                        commit(draft)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("None")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                    Button("Set") {
                        var draft = state
                        draft.opacity = 0.4
                        commit(draft)
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 5)
        }
    }

    // MARK: - Rules

    @ViewBuilder
    private var rulesSection: some View {
        ComponentRulesList(
            rules: spec.rules,
            onAdd: addRule,
            onDelete: deleteRule,
            onKindChange: updateRuleKind,
            onTextCommit: updateRuleText
        )
    }

    // MARK: - Mutations

    private func update(_ apply: (inout ButtonSpec) -> Void) {
        document.edit(actionName: "Edit Button", undoManager: undoManager) { spec in
            apply(&spec.components.button)
        }
    }

    private func addRule() {
        document.edit(actionName: "Add Button Rule", undoManager: undoManager) { spec in
            spec.components.button.rules.append(
                ComponentRule(kind: .text, text: "New rule")
            )
        }
    }

    private func deleteRule(_ id: UUID) {
        document.edit(actionName: "Delete Button Rule", undoManager: undoManager) { spec in
            spec.components.button.rules.removeAll { $0.id == id }
        }
    }

    private func updateRuleKind(_ id: UUID, _ kind: HierarchyRuleKind) {
        document.edit(actionName: "Edit Button Rule", undoManager: undoManager) { spec in
            if let index = spec.components.button.rules.firstIndex(where: { $0.id == id }) {
                spec.components.button.rules[index].kind = kind
            }
        }
    }

    private func updateRuleText(_ id: UUID, _ text: String) {
        document.edit(actionName: "Edit Button Rule", undoManager: undoManager) { spec in
            if let index = spec.components.button.rules.firstIndex(where: { $0.id == id }) {
                spec.components.button.rules[index].text = text
            }
        }
    }
}
