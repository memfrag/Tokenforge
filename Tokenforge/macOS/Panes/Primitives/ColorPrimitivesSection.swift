//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct ColorPrimitivesSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var primitives: [ColorPrimitive] {
        document.spec.primitives.color
    }

    var body: some View {
        SectionCard(title: "Color", aside: asideText) {
            Button {
                addColor()
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.accentColor)
        } content: {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 148, maximum: 220), spacing: 10)],
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(primitives) { primitive in
                    SwatchCard(
                        primitive: primitive,
                        onRenameCommit: { newName in
                            renameColor(oldName: primitive.name, newName: newName)
                        },
                        onHexCommit: { newHex in
                            updateHex(name: primitive.name, newHex: newHex)
                        },
                        onDelete: {
                            deleteColor(name: primitive.name)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Derived

    private var asideText: String {
        let total = primitives.count
        let warnings = primitives.filter { !KebabCase.isValid($0.name) }.count
        if warnings > 0 {
            return "\(total) values · \(warnings) warning\(warnings == 1 ? "" : "s")"
        }
        return "\(total) values"
    }

    // MARK: - Mutations

    private func addColor() {
        document.edit(actionName: "Add Color", undoManager: undoManager) { spec in
            let baseName = "new-color"
            var candidate = baseName
            var suffix = 1
            let existing = Set(spec.primitives.color.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(baseName)-\(suffix)"
            }
            spec.primitives.color.append(ColorPrimitive(name: candidate, hex: "#CCCCCC"))
        }
    }

    private func deleteColor(name: String) {
        document.edit(actionName: "Delete Color", undoManager: undoManager) { spec in
            spec.primitives.color.removeAll { $0.name == name }
        }
    }

    private func renameColor(oldName: String, newName: String) {
        guard oldName != newName else {
            return
        }
        document.edit(actionName: "Rename Color", undoManager: undoManager) { spec in
            guard let index = spec.primitives.color.firstIndex(where: { $0.name == oldName }) else {
                return
            }
            spec.primitives.color[index].name = newName
            spec.rewriteAllReferences(
                from: .primitive("color", oldName),
                to: .primitive("color", newName)
            )
        }
    }

    private func updateHex(name: String, newHex: String) {
        document.edit(actionName: "Edit Color Value", undoManager: undoManager) { spec in
            guard let index = spec.primitives.color.firstIndex(where: { $0.name == name }) else {
                return
            }
            spec.primitives.color[index].hex = newHex
        }
    }
}

// MARK: - Swatch card

private struct SwatchCard: View {

    let primitive: ColorPrimitive
    let onRenameCommit: (String) -> Void
    let onHexCommit: (String) -> Void
    let onDelete: () -> Void

    private var parsedColor: Color {
        Color(hex: primitive.hex) ?? Color.gray.opacity(0.35)
    }

    private var nameIsValid: Bool {
        KebabCase.isValid(primitive.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Color well
            ZStack(alignment: .topTrailing) {
                parsedColor
                    .frame(height: 64)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    )
                if !nameIsValid {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(.orange))
                        .overlay(Circle().stroke(Color(nsColor: .textBackgroundColor), lineWidth: 2))
                        .padding(6)
                }
            }

            // Meta
            VStack(alignment: .leading, spacing: 2) {
                CommitOnDefocusTextField(
                    placeholder: "name",
                    source: primitive.name,
                    font: .system(size: 11.5, weight: .medium),
                    onCommit: onRenameCommit
                )
                CommitOnDefocusTextField(
                    placeholder: "#RRGGBB",
                    source: primitive.hex,
                    font: .system(size: 10.5, design: .monospaced),
                    onCommit: onHexCommit
                )
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.separator)
                    .frame(height: 0.5)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(nameIsValid ? Color.clear : .orange, lineWidth: 1.25)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.separator, lineWidth: 0.5)
                .opacity(nameIsValid ? 1 : 0)
        )
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

