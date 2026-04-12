//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct StrokePrimitivesSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var primitives: [StrokePrimitive] {
        document.spec.primitives.stroke
    }

    var body: some View {
        SectionCard(title: "Stroke", aside: "\(primitives.count) widths") {
            AddPrimitiveButton(action: addStroke)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(primitives) { primitive in
                    NamedRow(
                        name: primitive.name,
                        onRenameCommit: { newName in rename(oldName: primitive.name, newName: newName) },
                        onDelete: { delete(name: primitive.name) }
                    ) {
                        Rectangle()
                            .fill(Color.primary.opacity(0.85))
                            .frame(width: 120, height: max(0.5, CGFloat(primitive.width)))
                            .padding(.vertical, 9)
                        Spacer(minLength: 8)
                        NumericDoubleField(source: primitive.width) { newValue in
                            updateWidth(name: primitive.name, newWidth: newValue)
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

    private func addStroke() {
        document.edit(actionName: "Add Stroke", undoManager: undoManager) { spec in
            let baseName = "stroke-new"
            var candidate = baseName
            var suffix = 1
            let existing = Set(spec.primitives.stroke.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(baseName)-\(suffix)"
            }
            spec.primitives.stroke.append(StrokePrimitive(name: candidate, width: 1))
        }
    }

    private func delete(name: String) {
        document.edit(actionName: "Delete Stroke", undoManager: undoManager) { spec in
            spec.primitives.stroke.removeAll { $0.name == name }
        }
    }

    private func rename(oldName: String, newName: String) {
        guard oldName != newName else {
            return
        }
        document.edit(actionName: "Rename Stroke", undoManager: undoManager) { spec in
            if let index = spec.primitives.stroke.firstIndex(where: { $0.name == oldName }) {
                spec.primitives.stroke[index].name = newName
            }
            spec.rewriteAllReferences(
                from: .primitive("stroke", oldName),
                to: .primitive("stroke", newName)
            )
        }
    }

    private func updateWidth(name: String, newWidth: Double) {
        document.edit(actionName: "Edit Stroke Width", undoManager: undoManager) { spec in
            if let index = spec.primitives.stroke.firstIndex(where: { $0.name == name }) {
                spec.primitives.stroke[index].width = newWidth
            }
        }
    }
}
