//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

// MARK: - ToastBanner

struct ToastBannerComponentEditor: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var spec: ToastBannerSpec { document.spec.components.toastBanner }
    private var colors: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.colors(document.spec) }
    private var radii: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.radiusAliases(document.spec) }

    var body: some View {
        variantsSection
        Divider().opacity(0.35)
        SectionCard(title: "Container") {
            EmptyView()
        } content: {
            ComponentFieldRow(
                label: "radius",
                reference: spec.radius,
                candidates: radii,
                referenceBuilder: { TokenRef.semantic("radius", $0) },
                onCommit: { ref in update { $0.radius = ref } }
            )
        }
        Divider().opacity(0.35)
        ComponentRulesList(
            rules: spec.rules,
            onAdd: { update { $0.rules.append(ComponentRule(kind: .text, text: "New rule")) } },
            onDelete: { id in update { $0.rules.removeAll { $0.id == id } } },
            onKindChange: { id, kind in update { draft in if let i = draft.rules.firstIndex(where: { $0.id == id }) { draft.rules[i].kind = kind } } },
            onTextCommit: { id, text in update { draft in if let i = draft.rules.firstIndex(where: { $0.id == id }) { draft.rules[i].text = text } } }
        )
    }

    private var variantsSection: some View {
        SectionCard(title: "Variants", aside: "4 statuses") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                variantEditor("info", variant: spec.variants.info) { new in update { $0.variants.info = new } }
                Divider().opacity(0.5)
                variantEditor("success", variant: spec.variants.success) { new in update { $0.variants.success = new } }
                Divider().opacity(0.5)
                variantEditor("warning", variant: spec.variants.warning) { new in update { $0.variants.warning = new } }
                Divider().opacity(0.5)
                variantEditor("error", variant: spec.variants.error) { new in update { $0.variants.error = new } }
            }
        }
    }

    @ViewBuilder
    private func variantEditor(
        _ title: String,
        variant: ToastBannerVariant,
        commit: @escaping (ToastBannerVariant) -> Void
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
                onCommit: { ref in var draft = variant; draft.background = ref; commit(draft) }
            )
            ComponentFieldRow(
                label: "label",
                reference: variant.label,
                candidates: colors,
                referenceBuilder: { TokenRef.semantic("color", $0) },
                onCommit: { ref in var draft = variant; draft.label = ref; commit(draft) }
            )
            ComponentFieldRow(
                label: "icon",
                reference: variant.iconColor,
                candidates: colors,
                referenceBuilder: { TokenRef.semantic("color", $0) },
                onCommit: { ref in var draft = variant; draft.iconColor = ref; commit(draft) }
            )
        }
    }

    private func update(_ apply: (inout ToastBannerSpec) -> Void) {
        document.edit(actionName: "Edit ToastBanner", undoManager: undoManager) { spec in
            apply(&spec.components.toastBanner)
        }
    }
}

// MARK: - BadgeTag

struct BadgeTagComponentEditor: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var spec: BadgeTagSpec { document.spec.components.badgeTag }
    private var colors: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.colors(document.spec) }
    private var radii: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.radiusAliases(document.spec) }
    private var spacings: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.spacingAliases(document.spec) }
    private var typeStyles: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.typeStyles(document.spec) }

    var body: some View {
        sizesSection
        Divider().opacity(0.35)
        variantsSection
        Divider().opacity(0.35)
        SectionCard(title: "Container") {
            EmptyView()
        } content: {
            ComponentFieldRow(
                label: "radius",
                reference: spec.radius,
                candidates: radii,
                referenceBuilder: { TokenRef.semantic("radius", $0) },
                onCommit: { ref in update { $0.radius = ref } }
            )
        }
        Divider().opacity(0.35)
        ComponentRulesList(
            rules: spec.rules,
            onAdd: { update { $0.rules.append(ComponentRule(kind: .text, text: "New rule")) } },
            onDelete: { id in update { $0.rules.removeAll { $0.id == id } } },
            onKindChange: { id, kind in update { draft in if let i = draft.rules.firstIndex(where: { $0.id == id }) { draft.rules[i].kind = kind } } },
            onTextCommit: { id, text in update { draft in if let i = draft.rules.firstIndex(where: { $0.id == id }) { draft.rules[i].text = text } } }
        )
    }

    private var sizesSection: some View {
        SectionCard(title: "Sizes", aside: "2 defined") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                sizeEditor("small", size: spec.sizes.small) { new in update { $0.sizes.small = new } }
                Divider().opacity(0.5)
                sizeEditor("medium", size: spec.sizes.medium) { new in update { $0.sizes.medium = new } }
            }
        }
    }

    @ViewBuilder
    private func sizeEditor(
        _ title: String,
        size: BadgeTagSize,
        commit: @escaping (BadgeTagSize) -> Void
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

    private var variantsSection: some View {
        SectionCard(title: "Variants", aside: "5 defined") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                variantEditor("neutral", variant: spec.variants.neutral) { new in update { $0.variants.neutral = new } }
                Divider().opacity(0.5)
                variantEditor("info", variant: spec.variants.info) { new in update { $0.variants.info = new } }
                Divider().opacity(0.5)
                variantEditor("success", variant: spec.variants.success) { new in update { $0.variants.success = new } }
                Divider().opacity(0.5)
                variantEditor("warning", variant: spec.variants.warning) { new in update { $0.variants.warning = new } }
                Divider().opacity(0.5)
                variantEditor("error", variant: spec.variants.error) { new in update { $0.variants.error = new } }
            }
        }
    }

    @ViewBuilder
    private func variantEditor(
        _ title: String,
        variant: BadgeTagVariant,
        commit: @escaping (BadgeTagVariant) -> Void
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
                onCommit: { ref in var draft = variant; draft.background = ref; commit(draft) }
            )
            ComponentFieldRow(
                label: "label",
                reference: variant.label,
                candidates: colors,
                referenceBuilder: { TokenRef.semantic("color", $0) },
                onCommit: { ref in var draft = variant; draft.label = ref; commit(draft) }
            )
        }
    }

    private func update(_ apply: (inout BadgeTagSpec) -> Void) {
        document.edit(actionName: "Edit BadgeTag", undoManager: undoManager) { spec in
            apply(&spec.components.badgeTag)
        }
    }
}
