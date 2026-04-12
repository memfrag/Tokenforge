//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct SpacingPrimitivesSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var primitives: [SpacingPrimitive] {
        document.spec.primitives.spacing
    }

    private var maxPoints: Double {
        max(1, primitives.map(\.points).max() ?? 1)
    }

    var body: some View {
        SectionCard(title: "Spacing", aside: "\(primitives.count) values") {
            AddPrimitiveButton(action: addSpacing)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(primitives) { primitive in
                    NamedRow(
                        name: primitive.name,
                        onRenameCommit: { newName in rename(oldName: primitive.name, newName: newName) },
                        onDelete: { delete(name: primitive.name) }
                    ) {
                        Capsule()
                            .fill(Color.accentColor.opacity(0.9))
                            .frame(
                                width: CGFloat(primitive.points / maxPoints) * 260,
                                height: 8
                            )
                        Spacer(minLength: 8)
                        NumericDoubleField(source: primitive.points) { newValue in
                            updateValue(name: primitive.name, newPoints: newValue)
                        }
                        Text("pt")
                            .font(.system(size: 10.5))
                            .foregroundStyle(.tertiary)
                    }
                    if primitive.id != primitives.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    // MARK: - Mutations

    private func addSpacing() {
        document.edit(actionName: "Add Spacing", undoManager: undoManager) { spec in
            let baseName = "sp-new"
            var candidate = baseName
            var suffix = 1
            let existing = Set(spec.primitives.spacing.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(baseName)-\(suffix)"
            }
            spec.primitives.spacing.append(SpacingPrimitive(name: candidate, points: 16))
        }
    }

    private func delete(name: String) {
        document.edit(actionName: "Delete Spacing", undoManager: undoManager) { spec in
            spec.primitives.spacing.removeAll { $0.name == name }
        }
    }

    private func rename(oldName: String, newName: String) {
        guard oldName != newName else {
            return
        }
        document.edit(actionName: "Rename Spacing", undoManager: undoManager) { spec in
            if let index = spec.primitives.spacing.firstIndex(where: { $0.name == oldName }) {
                spec.primitives.spacing[index].name = newName
            }
            spec.rewriteAllReferences(
                from: .primitive("spacing", oldName),
                to: .primitive("spacing", newName)
            )
        }
    }

    private func updateValue(name: String, newPoints: Double) {
        document.edit(actionName: "Edit Spacing Value", undoManager: undoManager) { spec in
            if let index = spec.primitives.spacing.firstIndex(where: { $0.name == name }) {
                spec.primitives.spacing[index].points = newPoints
            }
        }
    }
}
