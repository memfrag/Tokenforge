//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct ElevationPrimitivesSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var primitives: [ElevationPrimitive] {
        document.spec.primitives.elevation
    }

    var body: some View {
        SectionCard(title: "Elevation", aside: "\(primitives.count) values") {
            AddPrimitiveButton(action: addElevation)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(primitives) { primitive in
                    NamedRow(
                        name: primitive.name,
                        onRenameCommit: { newName in rename(oldName: primitive.name, newName: newName) },
                        onDelete: { delete(name: primitive.name) }
                    ) {
                        // Shadow preview swatch
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color(nsColor: .textBackgroundColor))
                            .frame(width: 42, height: 28)
                            .shadow(
                                color: .black.opacity(primitive.opacity),
                                radius: primitive.blur / 2,
                                x: 0,
                                y: primitive.offsetY
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(.separator, lineWidth: 0.5)
                            )
                            .padding(.leading, 4)
                            .padding(.trailing, 16)

                        Group {
                            labeled("y") {
                                NumericDoubleField(source: primitive.offsetY, width: 52) { newValue in
                                    update(name: primitive.name) { $0.offsetY = newValue }
                                }
                            }
                            labeled("blur") {
                                NumericDoubleField(source: primitive.blur, width: 52) { newValue in
                                    update(name: primitive.name) { $0.blur = newValue }
                                }
                            }
                            labeled("α") {
                                NumericDoubleField(source: primitive.opacity, width: 56) { newValue in
                                    update(name: primitive.name) { $0.opacity = newValue }
                                }
                            }
                        }
                    }
                    if primitive.id != primitives.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func labeled<V: View>(_ label: String, @ViewBuilder content: () -> V) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            content()
        }
    }

    // MARK: - Mutations

    private func addElevation() {
        document.edit(actionName: "Add Elevation", undoManager: undoManager) { spec in
            let baseName = "elev-new"
            var candidate = baseName
            var suffix = 1
            let existing = Set(spec.primitives.elevation.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(baseName)-\(suffix)"
            }
            spec.primitives.elevation.append(
                ElevationPrimitive(name: candidate, offsetY: 2, blur: 6, opacity: 0.1)
            )
        }
    }

    private func delete(name: String) {
        document.edit(actionName: "Delete Elevation", undoManager: undoManager) { spec in
            spec.primitives.elevation.removeAll { $0.name == name }
        }
    }

    private func rename(oldName: String, newName: String) {
        guard oldName != newName else {
            return
        }
        document.edit(actionName: "Rename Elevation", undoManager: undoManager) { spec in
            if let index = spec.primitives.elevation.firstIndex(where: { $0.name == oldName }) {
                spec.primitives.elevation[index].name = newName
            }
            spec.rewriteAllReferences(
                from: .primitive("elevation", oldName),
                to: .primitive("elevation", newName)
            )
        }
    }

    private func update(name: String, _ apply: (inout ElevationPrimitive) -> Void) {
        document.edit(actionName: "Edit Elevation Value", undoManager: undoManager) { spec in
            if let index = spec.primitives.elevation.firstIndex(where: { $0.name == name }) {
                apply(&spec.primitives.elevation[index])
            }
        }
    }
}
