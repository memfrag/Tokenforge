//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct TypographyPrimitivesSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var typography: TypographyPrimitives {
        document.spec.primitives.typography
    }

    var body: some View {
        SectionCard(title: "Typography", aside: asideText) {
            Menu {
                Button("Add Font Family", action: addFontFamily)
                Button("Add Font Size", action: addFontSize)
                Button("Add Font Weight", action: addFontWeight)
                Button("Add Line Height", action: addLineHeight)
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .labelStyle(.titleAndIcon)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .foregroundStyle(Color.accentColor)
        } content: {
            VStack(alignment: .leading, spacing: 18) {
                families
                sizes
                weights
                lineHeights
            }
        }
    }

    // MARK: - Derived

    private var asideText: String {
        "\(typography.fontFamilies.count) families · \(typography.fontSizes.count) sizes · \(typography.fontWeights.count) weights · \(typography.lineHeights.count) line heights"
    }

    // MARK: - Subsections

    private var families: some View {
        Group {
            subsectionLabel("Font families")
            VStack(alignment: .leading, spacing: 0) {
                ForEach(typography.fontFamilies) { primitive in
                    NamedRow(
                        name: primitive.name,
                        onRenameCommit: { new in renameFamily(oldName: primitive.name, newName: new) },
                        onDelete: { deleteFamily(name: primitive.name) }
                    ) {
                        CommitOnDefocusTextField(
                            placeholder: "Family name",
                            source: primitive.family,
                            font: .system(size: 12)
                        ) { new in
                            updateFamily(name: primitive.name) { $0.family = new }
                        }
                        .frame(maxWidth: 220)
                        Spacer(minLength: 6)
                        Toggle(isOn: Binding(
                            get: { primitive.isCustom },
                            set: { new in updateFamily(name: primitive.name) { $0.isCustom = new } }
                        )) {
                            Text("Custom")
                                .font(.system(size: 10.5))
                                .foregroundStyle(.tertiary)
                        }
                        .toggleStyle(.checkbox)
                    }
                    if primitive.id != typography.fontFamilies.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    private var sizes: some View {
        Group {
            subsectionLabel("Font sizes")
            VStack(alignment: .leading, spacing: 0) {
                ForEach(typography.fontSizes) { primitive in
                    NamedRow(
                        name: primitive.name,
                        onRenameCommit: { new in renameSize(oldName: primitive.name, newName: new) },
                        onDelete: { deleteSize(name: primitive.name) }
                    ) {
                        Text("Sample")
                            .font(.system(size: max(8, CGFloat(primitive.points))))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: 160, alignment: .leading)
                        Spacer(minLength: 6)
                        NumericDoubleField(source: primitive.points) { new in
                            updateSize(name: primitive.name) { $0.points = new }
                        }
                        Text("pt")
                            .font(.system(size: 10.5))
                            .foregroundStyle(.tertiary)
                    }
                    if primitive.id != typography.fontSizes.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    private var weights: some View {
        Group {
            subsectionLabel("Font weights")
            VStack(alignment: .leading, spacing: 0) {
                ForEach(typography.fontWeights) { primitive in
                    NamedRow(
                        name: primitive.name,
                        onRenameCommit: { new in renameWeight(oldName: primitive.name, newName: new) },
                        onDelete: { deleteWeight(name: primitive.name) }
                    ) {
                        Text("Sample")
                            .font(.system(size: 13, weight: swiftUIWeight(for: primitive.weight)))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 120, alignment: .leading)
                        Spacer(minLength: 6)
                        NumericIntField(source: primitive.weight) { new in
                            updateWeight(name: primitive.name) { $0.weight = new }
                        }
                    }
                    if primitive.id != typography.fontWeights.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    private var lineHeights: some View {
        Group {
            subsectionLabel("Line heights")
            VStack(alignment: .leading, spacing: 0) {
                ForEach(typography.lineHeights) { primitive in
                    NamedRow(
                        name: primitive.name,
                        onRenameCommit: { new in renameLineHeight(oldName: primitive.name, newName: new) },
                        onDelete: { deleteLineHeight(name: primitive.name) }
                    ) {
                        Spacer(minLength: 0)
                        NumericDoubleField(source: primitive.multiplier) { new in
                            updateLineHeight(name: primitive.name) { $0.multiplier = new }
                        }
                        Text("×")
                            .font(.system(size: 10.5))
                            .foregroundStyle(.tertiary)
                    }
                    if primitive.id != typography.lineHeights.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    // MARK: - Subsection label

    @ViewBuilder
    private func subsectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(.tertiary)
    }

    private func swiftUIWeight(for cssWeight: Int) -> Font.Weight {
        switch cssWeight {
        case ..<200: return .ultraLight
        case 200..<300: return .thin
        case 300..<400: return .light
        case 400..<500: return .regular
        case 500..<600: return .medium
        case 600..<700: return .semibold
        case 700..<800: return .bold
        case 800..<900: return .heavy
        default: return .black
        }
    }

    // MARK: - Mutations — Font families

    private func addFontFamily() {
        document.edit(actionName: "Add Font Family", undoManager: undoManager) { spec in
            let base = "family-new"
            var candidate = base
            var suffix = 1
            let existing = Set(spec.primitives.typography.fontFamilies.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(base)-\(suffix)"
            }
            spec.primitives.typography.fontFamilies.append(
                FontFamilyPrimitive(name: candidate, family: "SF Pro", isCustom: false)
            )
        }
    }

    private func deleteFamily(name: String) {
        document.edit(actionName: "Delete Font Family", undoManager: undoManager) { spec in
            spec.primitives.typography.fontFamilies.removeAll { $0.name == name }
        }
    }

    private func renameFamily(oldName: String, newName: String) {
        guard oldName != newName else {
            return
        }
        document.edit(actionName: "Rename Font Family", undoManager: undoManager) { spec in
            if let index = spec.primitives.typography.fontFamilies.firstIndex(where: { $0.name == oldName }) {
                spec.primitives.typography.fontFamilies[index].name = newName
            }
            spec.rewriteAllReferences(
                from: .primitivePath("typography", "fontFamilies", oldName),
                to: .primitivePath("typography", "fontFamilies", newName)
            )
        }
    }

    private func updateFamily(name: String, _ apply: (inout FontFamilyPrimitive) -> Void) {
        document.edit(actionName: "Edit Font Family", undoManager: undoManager) { spec in
            if let index = spec.primitives.typography.fontFamilies.firstIndex(where: { $0.name == name }) {
                apply(&spec.primitives.typography.fontFamilies[index])
            }
        }
    }

    // MARK: - Mutations — Font sizes

    private func addFontSize() {
        document.edit(actionName: "Add Font Size", undoManager: undoManager) { spec in
            let base = "size-new"
            var candidate = base
            var suffix = 1
            let existing = Set(spec.primitives.typography.fontSizes.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(base)-\(suffix)"
            }
            spec.primitives.typography.fontSizes.append(
                FontSizePrimitive(name: candidate, points: 16)
            )
        }
    }

    private func deleteSize(name: String) {
        document.edit(actionName: "Delete Font Size", undoManager: undoManager) { spec in
            spec.primitives.typography.fontSizes.removeAll { $0.name == name }
        }
    }

    private func renameSize(oldName: String, newName: String) {
        guard oldName != newName else {
            return
        }
        document.edit(actionName: "Rename Font Size", undoManager: undoManager) { spec in
            if let index = spec.primitives.typography.fontSizes.firstIndex(where: { $0.name == oldName }) {
                spec.primitives.typography.fontSizes[index].name = newName
            }
            spec.rewriteAllReferences(
                from: .primitivePath("typography", "fontSizes", oldName),
                to: .primitivePath("typography", "fontSizes", newName)
            )
        }
    }

    private func updateSize(name: String, _ apply: (inout FontSizePrimitive) -> Void) {
        document.edit(actionName: "Edit Font Size", undoManager: undoManager) { spec in
            if let index = spec.primitives.typography.fontSizes.firstIndex(where: { $0.name == name }) {
                apply(&spec.primitives.typography.fontSizes[index])
            }
        }
    }

    // MARK: - Mutations — Font weights

    private func addFontWeight() {
        document.edit(actionName: "Add Font Weight", undoManager: undoManager) { spec in
            let base = "weight-new"
            var candidate = base
            var suffix = 1
            let existing = Set(spec.primitives.typography.fontWeights.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(base)-\(suffix)"
            }
            spec.primitives.typography.fontWeights.append(
                FontWeightPrimitive(name: candidate, weight: 400)
            )
        }
    }

    private func deleteWeight(name: String) {
        document.edit(actionName: "Delete Font Weight", undoManager: undoManager) { spec in
            spec.primitives.typography.fontWeights.removeAll { $0.name == name }
        }
    }

    private func renameWeight(oldName: String, newName: String) {
        guard oldName != newName else {
            return
        }
        document.edit(actionName: "Rename Font Weight", undoManager: undoManager) { spec in
            if let index = spec.primitives.typography.fontWeights.firstIndex(where: { $0.name == oldName }) {
                spec.primitives.typography.fontWeights[index].name = newName
            }
            spec.rewriteAllReferences(
                from: .primitivePath("typography", "fontWeights", oldName),
                to: .primitivePath("typography", "fontWeights", newName)
            )
        }
    }

    private func updateWeight(name: String, _ apply: (inout FontWeightPrimitive) -> Void) {
        document.edit(actionName: "Edit Font Weight", undoManager: undoManager) { spec in
            if let index = spec.primitives.typography.fontWeights.firstIndex(where: { $0.name == name }) {
                apply(&spec.primitives.typography.fontWeights[index])
            }
        }
    }

    // MARK: - Mutations — Line heights

    private func addLineHeight() {
        document.edit(actionName: "Add Line Height", undoManager: undoManager) { spec in
            let base = "line-new"
            var candidate = base
            var suffix = 1
            let existing = Set(spec.primitives.typography.lineHeights.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(base)-\(suffix)"
            }
            spec.primitives.typography.lineHeights.append(
                LineHeightPrimitive(name: candidate, multiplier: 1.4)
            )
        }
    }

    private func deleteLineHeight(name: String) {
        document.edit(actionName: "Delete Line Height", undoManager: undoManager) { spec in
            spec.primitives.typography.lineHeights.removeAll { $0.name == name }
        }
    }

    private func renameLineHeight(oldName: String, newName: String) {
        guard oldName != newName else {
            return
        }
        document.edit(actionName: "Rename Line Height", undoManager: undoManager) { spec in
            if let index = spec.primitives.typography.lineHeights.firstIndex(where: { $0.name == oldName }) {
                spec.primitives.typography.lineHeights[index].name = newName
            }
            spec.rewriteAllReferences(
                from: .primitivePath("typography", "lineHeights", oldName),
                to: .primitivePath("typography", "lineHeights", newName)
            )
        }
    }

    private func updateLineHeight(name: String, _ apply: (inout LineHeightPrimitive) -> Void) {
        document.edit(actionName: "Edit Line Height", undoManager: undoManager) { spec in
            if let index = spec.primitives.typography.lineHeights.firstIndex(where: { $0.name == name }) {
                apply(&spec.primitives.typography.lineHeights[index])
            }
        }
    }
}
