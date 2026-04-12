//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct MotionPrimitivesSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var durations: [DurationPrimitive] {
        document.spec.primitives.motion.durations
    }

    private var curves: [CurvePrimitive] {
        document.spec.primitives.motion.curves
    }

    var body: some View {
        SectionCard(title: "Motion", aside: "\(durations.count) durations · \(curves.count) curves") {
            Menu {
                Button("Add Duration", action: addDuration)
                Button("Add Curve", action: addCurve)
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .labelStyle(.titleAndIcon)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .foregroundStyle(Color.accentColor)
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                subsectionLabel("Durations")
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(durations) { primitive in
                        NamedRow(
                            name: primitive.name,
                            onRenameCommit: { newName in renameDuration(oldName: primitive.name, newName: newName) },
                            onDelete: { deleteDuration(name: primitive.name) }
                        ) {
                            Spacer(minLength: 0)
                            NumericIntField(source: primitive.milliseconds) { newMS in
                                updateDuration(name: primitive.name, newMS: newMS)
                            }
                            Text("ms")
                                .font(.system(size: 10.5))
                                .foregroundStyle(.tertiary)
                        }
                        if primitive.id != durations.last?.id {
                            Divider().opacity(0.4)
                        }
                    }
                }

                subsectionLabel("Curves")
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(curves) { primitive in
                        NamedRow(
                            name: primitive.name,
                            onRenameCommit: { newName in renameCurve(oldName: primitive.name, newName: newName) },
                            onDelete: { deleteCurve(name: primitive.name) }
                        ) {
                            Spacer(minLength: 0)
                            bezierField("x1", primitive.x1) { new in updateCurveControl(name: primitive.name) { $0.x1 = new } }
                            bezierField("y1", primitive.y1) { new in updateCurveControl(name: primitive.name) { $0.y1 = new } }
                            bezierField("x2", primitive.x2) { new in updateCurveControl(name: primitive.name) { $0.x2 = new } }
                            bezierField("y2", primitive.y2) { new in updateCurveControl(name: primitive.name) { $0.y2 = new } }
                        }
                        if primitive.id != curves.last?.id {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func subsectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(.tertiary)
    }

    @ViewBuilder
    private func bezierField(_ label: String, _ value: Double, commit: @escaping (Double) -> Void) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            NumericDoubleField(source: value, width: 48, onCommit: commit)
        }
    }

    // MARK: - Mutations — Durations

    private func addDuration() {
        document.edit(actionName: "Add Duration", undoManager: undoManager) { spec in
            let baseName = "duration-new"
            var candidate = baseName
            var suffix = 1
            let existing = Set(spec.primitives.motion.durations.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(baseName)-\(suffix)"
            }
            spec.primitives.motion.durations.append(
                DurationPrimitive(name: candidate, milliseconds: 200)
            )
        }
    }

    private func deleteDuration(name: String) {
        document.edit(actionName: "Delete Duration", undoManager: undoManager) { spec in
            spec.primitives.motion.durations.removeAll { $0.name == name }
        }
    }

    private func renameDuration(oldName: String, newName: String) {
        guard oldName != newName else {
            return
        }
        document.edit(actionName: "Rename Duration", undoManager: undoManager) { spec in
            if let index = spec.primitives.motion.durations.firstIndex(where: { $0.name == oldName }) {
                spec.primitives.motion.durations[index].name = newName
            }
            spec.rewriteAllReferences(
                from: .primitivePath("motion", "durations", oldName),
                to: .primitivePath("motion", "durations", newName)
            )
        }
    }

    private func updateDuration(name: String, newMS: Int) {
        document.edit(actionName: "Edit Duration", undoManager: undoManager) { spec in
            if let index = spec.primitives.motion.durations.firstIndex(where: { $0.name == name }) {
                spec.primitives.motion.durations[index].milliseconds = newMS
            }
        }
    }

    // MARK: - Mutations — Curves

    private func addCurve() {
        document.edit(actionName: "Add Curve", undoManager: undoManager) { spec in
            let baseName = "curve-new"
            var candidate = baseName
            var suffix = 1
            let existing = Set(spec.primitives.motion.curves.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(baseName)-\(suffix)"
            }
            spec.primitives.motion.curves.append(
                CurvePrimitive(name: candidate, x1: 0.4, y1: 0, x2: 0.2, y2: 1)
            )
        }
    }

    private func deleteCurve(name: String) {
        document.edit(actionName: "Delete Curve", undoManager: undoManager) { spec in
            spec.primitives.motion.curves.removeAll { $0.name == name }
        }
    }

    private func renameCurve(oldName: String, newName: String) {
        guard oldName != newName else {
            return
        }
        document.edit(actionName: "Rename Curve", undoManager: undoManager) { spec in
            if let index = spec.primitives.motion.curves.firstIndex(where: { $0.name == oldName }) {
                spec.primitives.motion.curves[index].name = newName
            }
            spec.rewriteAllReferences(
                from: .primitivePath("motion", "curves", oldName),
                to: .primitivePath("motion", "curves", newName)
            )
        }
    }

    private func updateCurveControl(name: String, _ apply: (inout CurvePrimitive) -> Void) {
        document.edit(actionName: "Edit Curve", undoManager: undoManager) { spec in
            if let index = spec.primitives.motion.curves.firstIndex(where: { $0.name == name }) {
                apply(&spec.primitives.motion.curves[index])
            }
        }
    }
}
