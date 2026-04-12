//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

// MARK: - ListItem

struct ListItemComponentEditor: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var spec: ListItemSpec { document.spec.components.listItem }

    private var colors: [PrimitiveReferencePicker.Candidate] {
        ComponentCandidates.colors(document.spec)
    }
    private var typeStyles: [PrimitiveReferencePicker.Candidate] {
        ComponentCandidates.typeStyles(document.spec)
    }

    var body: some View {
        SectionCard(title: "Surface") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                ComponentFieldRow(
                    label: "background",
                    reference: spec.background,
                    candidates: colors,
                    referenceBuilder: { TokenRef.semantic("color", $0) },
                    onCommit: { ref in update { $0.background = ref } }
                )
                ComponentFieldRow(
                    label: "title style",
                    reference: spec.titleStyle,
                    candidates: typeStyles,
                    referenceBuilder: { TokenRef.semantic("type", $0) },
                    onCommit: { ref in update { $0.titleStyle = ref } }
                )
                ComponentFieldRow(
                    label: "subtitle style",
                    reference: spec.subtitleStyle,
                    candidates: typeStyles,
                    referenceBuilder: { TokenRef.semantic("type", $0) },
                    onCommit: { ref in update { $0.subtitleStyle = ref } }
                )
                OptionalComponentFieldRow(
                    label: "leading icon",
                    reference: spec.leadingIconColor,
                    candidates: colors,
                    referenceBuilder: { TokenRef.semantic("color", $0) },
                    onCommit: { ref in update { $0.leadingIconColor = ref } }
                )
                OptionalComponentFieldRow(
                    label: "trailing",
                    reference: spec.trailingColor,
                    candidates: colors,
                    referenceBuilder: { TokenRef.semantic("color", $0) },
                    onCommit: { ref in update { $0.trailingColor = ref } }
                )
                ComponentFieldRow(
                    label: "separator",
                    reference: spec.separatorColor,
                    candidates: colors,
                    referenceBuilder: { TokenRef.semantic("color", $0) },
                    onCommit: { ref in update { $0.separatorColor = ref } }
                )
                ComponentNumericFieldRow(
                    label: "row height",
                    value: spec.rowHeightPoints,
                    onCommit: { new in update { $0.rowHeightPoints = new } }
                )
            }
        }
        Divider().opacity(0.35)
        ComponentRulesList(
            rules: spec.rules,
            onAdd: { update { $0.rules.append(ComponentRule(kind: .text, text: "New rule")) } },
            onDelete: { id in update { $0.rules.removeAll { $0.id == id } } },
            onKindChange: { id, kind in
                update { draft in
                    if let index = draft.rules.firstIndex(where: { $0.id == id }) {
                        draft.rules[index].kind = kind
                    }
                }
            },
            onTextCommit: { id, text in
                update { draft in
                    if let index = draft.rules.firstIndex(where: { $0.id == id }) {
                        draft.rules[index].text = text
                    }
                }
            }
        )
    }

    private func update(_ apply: (inout ListItemSpec) -> Void) {
        document.edit(actionName: "Edit ListItem", undoManager: undoManager) { spec in
            apply(&spec.components.listItem)
        }
    }
}

// MARK: - NavBar

struct NavBarComponentEditor: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var spec: NavBarSpec { document.spec.components.navBar }

    private var colors: [PrimitiveReferencePicker.Candidate] {
        ComponentCandidates.colors(document.spec)
    }
    private var typeStyles: [PrimitiveReferencePicker.Candidate] {
        ComponentCandidates.typeStyles(document.spec)
    }

    var body: some View {
        SectionCard(title: "Surface") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                ComponentFieldRow(
                    label: "background",
                    reference: spec.background,
                    candidates: colors,
                    referenceBuilder: { TokenRef.semantic("color", $0) },
                    onCommit: { ref in update { $0.background = ref } }
                )
                ComponentFieldRow(
                    label: "title style",
                    reference: spec.titleStyle,
                    candidates: typeStyles,
                    referenceBuilder: { TokenRef.semantic("type", $0) },
                    onCommit: { ref in update { $0.titleStyle = ref } }
                )
                OptionalComponentFieldRow(
                    label: "large title style",
                    reference: spec.largeTitleStyle,
                    candidates: typeStyles,
                    referenceBuilder: { TokenRef.semantic("type", $0) },
                    onCommit: { ref in update { $0.largeTitleStyle = ref } }
                )
                ComponentFieldRow(
                    label: "leading action",
                    reference: spec.leadingActionColor,
                    candidates: colors,
                    referenceBuilder: { TokenRef.semantic("color", $0) },
                    onCommit: { ref in update { $0.leadingActionColor = ref } }
                )
                ComponentFieldRow(
                    label: "trailing action",
                    reference: spec.trailingActionColor,
                    candidates: colors,
                    referenceBuilder: { TokenRef.semantic("color", $0) },
                    onCommit: { ref in update { $0.trailingActionColor = ref } }
                )
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("supports large title")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 130, alignment: .leading)
                    Toggle(isOn: Binding(
                        get: { spec.supportsLargeTitle },
                        set: { new in update { $0.supportsLargeTitle = new } }
                    )) {
                        EmptyView()
                    }
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 5)
            }
        }
        Divider().opacity(0.35)
        ComponentRulesList(
            rules: spec.rules,
            onAdd: { update { $0.rules.append(ComponentRule(kind: .text, text: "New rule")) } },
            onDelete: { id in update { $0.rules.removeAll { $0.id == id } } },
            onKindChange: { id, kind in
                update { draft in
                    if let index = draft.rules.firstIndex(where: { $0.id == id }) {
                        draft.rules[index].kind = kind
                    }
                }
            },
            onTextCommit: { id, text in
                update { draft in
                    if let index = draft.rules.firstIndex(where: { $0.id == id }) {
                        draft.rules[index].text = text
                    }
                }
            }
        )
    }

    private func update(_ apply: (inout NavBarSpec) -> Void) {
        document.edit(actionName: "Edit NavBar", undoManager: undoManager) { spec in
            apply(&spec.components.navBar)
        }
    }
}

// MARK: - TabBar

struct TabBarComponentEditor: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var spec: TabBarSpec { document.spec.components.tabBar }
    private var colors: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.colors(document.spec) }
    private var typeStyles: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.typeStyles(document.spec) }

    var body: some View {
        SectionCard(title: "Surface") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                ComponentFieldRow(label: "background", reference: spec.background, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.background = ref } })
                ComponentFieldRow(label: "item selected", reference: spec.itemSelectedColor, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.itemSelectedColor = ref } })
                ComponentFieldRow(label: "item unselected", reference: spec.itemUnselectedColor, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.itemUnselectedColor = ref } })
                ComponentFieldRow(label: "label style", reference: spec.labelStyle, candidates: typeStyles, referenceBuilder: { TokenRef.semantic("type", $0) }, onCommit: { ref in update { $0.labelStyle = ref } })
            }
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

    private func update(_ apply: (inout TabBarSpec) -> Void) {
        document.edit(actionName: "Edit TabBar", undoManager: undoManager) { spec in
            apply(&spec.components.tabBar)
        }
    }
}

// MARK: - Toolbar

struct ToolbarComponentEditor: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var spec: ToolbarSpec { document.spec.components.toolbar }
    private var colors: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.colors(document.spec) }

    var body: some View {
        SectionCard(title: "Surface") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                ComponentFieldRow(label: "background", reference: spec.background, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.background = ref } })
                ComponentFieldRow(label: "action color", reference: spec.actionColor, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.actionColor = ref } })
                ComponentFieldRow(label: "separator", reference: spec.separatorColor, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.separatorColor = ref } })
            }
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

    private func update(_ apply: (inout ToolbarSpec) -> Void) {
        document.edit(actionName: "Edit Toolbar", undoManager: undoManager) { spec in
            apply(&spec.components.toolbar)
        }
    }
}

// MARK: - SegmentedControl

struct SegmentedControlComponentEditor: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var spec: SegmentedControlSpec { document.spec.components.segmentedControl }
    private var colors: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.colors(document.spec) }
    private var radii: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.radiusAliases(document.spec) }

    var body: some View {
        SectionCard(title: "Surface") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                ComponentFieldRow(label: "track bg", reference: spec.trackBackground, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.trackBackground = ref } })
                ComponentFieldRow(label: "selected bg", reference: spec.selectedBackground, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.selectedBackground = ref } })
                ComponentFieldRow(label: "label color", reference: spec.labelColor, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.labelColor = ref } })
                ComponentFieldRow(label: "selected label", reference: spec.selectedLabelColor, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.selectedLabelColor = ref } })
                ComponentFieldRow(label: "radius", reference: spec.radius, candidates: radii, referenceBuilder: { TokenRef.semantic("radius", $0) }, onCommit: { ref in update { $0.radius = ref } })
            }
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

    private func update(_ apply: (inout SegmentedControlSpec) -> Void) {
        document.edit(actionName: "Edit SegmentedControl", undoManager: undoManager) { spec in
            apply(&spec.components.segmentedControl)
        }
    }
}

// MARK: - Toggle

struct ToggleComponentEditor: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var spec: ToggleSpec { document.spec.components.toggle }
    private var colors: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.colors(document.spec) }

    var body: some View {
        SectionCard(title: "Surface") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                ComponentFieldRow(label: "track on", reference: spec.trackOn, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.trackOn = ref } })
                ComponentFieldRow(label: "track off", reference: spec.trackOff, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.trackOff = ref } })
                ComponentFieldRow(label: "thumb", reference: spec.thumbColor, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.thumbColor = ref } })
            }
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

    private func update(_ apply: (inout ToggleSpec) -> Void) {
        document.edit(actionName: "Edit Toggle", undoManager: undoManager) { spec in
            apply(&spec.components.toggle)
        }
    }
}

// MARK: - Alert

struct AlertComponentEditor: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var spec: AlertSpec { document.spec.components.alert }
    private var colors: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.colors(document.spec) }
    private var radii: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.radiusAliases(document.spec) }
    private var typeStyles: [PrimitiveReferencePicker.Candidate] { ComponentCandidates.typeStyles(document.spec) }

    var body: some View {
        SectionCard(title: "Surface") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                ComponentFieldRow(label: "surface", reference: spec.surface, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.surface = ref } })
                ComponentFieldRow(label: "title style", reference: spec.titleStyle, candidates: typeStyles, referenceBuilder: { TokenRef.semantic("type", $0) }, onCommit: { ref in update { $0.titleStyle = ref } })
                ComponentFieldRow(label: "body style", reference: spec.bodyStyle, candidates: typeStyles, referenceBuilder: { TokenRef.semantic("type", $0) }, onCommit: { ref in update { $0.bodyStyle = ref } })
                ComponentFieldRow(label: "action color", reference: spec.actionColor, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.actionColor = ref } })
                ComponentFieldRow(label: "destructive", reference: spec.destructiveActionColor, candidates: colors, referenceBuilder: { TokenRef.semantic("color", $0) }, onCommit: { ref in update { $0.destructiveActionColor = ref } })
                ComponentFieldRow(label: "radius", reference: spec.radius, candidates: radii, referenceBuilder: { TokenRef.semantic("radius", $0) }, onCommit: { ref in update { $0.radius = ref } })
            }
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

    private func update(_ apply: (inout AlertSpec) -> Void) {
        document.edit(actionName: "Edit Alert", undoManager: undoManager) { spec in
            apply(&spec.components.alert)
        }
    }
}
