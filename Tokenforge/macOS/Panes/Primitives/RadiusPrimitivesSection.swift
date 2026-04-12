//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct RadiusPrimitivesSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var primitives: [RadiusPrimitive] {
        document.spec.primitives.radius
    }

    var body: some View {
        SectionCard(title: "Radius", aside: "\(primitives.count) values") {
            AddPrimitiveButton(action: addRadius)
        } content: {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 128, maximum: 200), spacing: 10)],
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(primitives) { primitive in
                    RadiusCard(
                        primitive: primitive,
                        onRenameCommit: { newName in rename(oldName: primitive.name, newName: newName) },
                        onPointsCommit: { newPoints in updatePoints(name: primitive.name, newPoints: newPoints) },
                        onDelete: { delete(name: primitive.name) }
                    )
                }
            }
        }
    }

    // MARK: - Mutations

    private func addRadius() {
        document.edit(actionName: "Add Radius", undoManager: undoManager) { spec in
            let baseName = "radius-new"
            var candidate = baseName
            var suffix = 1
            let existing = Set(spec.primitives.radius.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(baseName)-\(suffix)"
            }
            spec.primitives.radius.append(RadiusPrimitive(name: candidate, points: 12))
        }
    }

    private func delete(name: String) {
        document.edit(actionName: "Delete Radius", undoManager: undoManager) { spec in
            spec.primitives.radius.removeAll { $0.name == name }
        }
    }

    private func rename(oldName: String, newName: String) {
        guard oldName != newName else {
            return
        }
        document.edit(actionName: "Rename Radius", undoManager: undoManager) { spec in
            if let index = spec.primitives.radius.firstIndex(where: { $0.name == oldName }) {
                spec.primitives.radius[index].name = newName
            }
            spec.rewriteAllReferences(
                from: .primitive("radius", oldName),
                to: .primitive("radius", newName)
            )
        }
    }

    private func updatePoints(name: String, newPoints: Double) {
        document.edit(actionName: "Edit Radius Value", undoManager: undoManager) { spec in
            if let index = spec.primitives.radius.firstIndex(where: { $0.name == name }) {
                spec.primitives.radius[index].points = newPoints
            }
        }
    }
}

private struct RadiusCard: View {

    let primitive: RadiusPrimitive
    let onRenameCommit: (String) -> Void
    let onPointsCommit: (Double) -> Void
    let onDelete: () -> Void

    private var nameIsValid: Bool {
        KebabCase.isValid(primitive.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: max(0, primitive.points), style: .continuous)
                .fill(Color.accentColor.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: max(0, primitive.points), style: .continuous)
                        .stroke(Color.accentColor, lineWidth: 1)
                )
                .frame(height: 54)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                CommitOnDefocusTextField(
                    source: primitive.name,
                    font: .system(size: 11.5, design: .monospaced),
                    onCommit: onRenameCommit
                )
                .foregroundStyle(nameIsValid ? Color.primary : Color.orange)
                Spacer(minLength: 6)
                NumericDoubleField(source: primitive.points, width: 52, onCommit: onPointsCommit)
                Text("pt")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(nameIsValid ? AnyShapeStyle(.separator) : AnyShapeStyle(Color.orange),
                        lineWidth: nameIsValid ? 0.5 : 1.25)
        )
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
