//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Shared editable row for primitive sections where each row has a name,
/// one or more numeric fields, and a kebab-case lint badge.
///
/// `trailing` hosts the value editor(s); the row handles the name field,
/// delete affordance, and lint warning.
///
struct NamedRow<Trailing: View>: View {

    let name: String
    let onRenameCommit: (String) -> Void
    let onDelete: () -> Void
    @ViewBuilder let trailing: () -> Trailing

    private var nameIsValid: Bool {
        KebabCase.isValid(name)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .trailing) {
                CommitOnDefocusTextField(
                    placeholder: "name",
                    source: name,
                    font: .system(size: 12, design: .monospaced),
                    onCommit: onRenameCommit
                )
                .foregroundStyle(nameIsValid ? Color.primary : Color.orange)
                .frame(maxWidth: 140, alignment: .leading)
                if !nameIsValid {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                        .padding(.trailing, 2)
                }
            }
            Divider()
                .frame(height: 14)
                .overlay(Color.primary.opacity(0.08))
            trailing()
            Spacer(minLength: 8)
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

/// Small trailing "add" button used inside SectionCard trailing slots.
struct AddPrimitiveButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Label("Add", systemImage: "plus")
                .font(.system(size: 11, weight: .medium))
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Color.accentColor)
    }
}

/// Wraps a numeric `Double` field with commit-on-defocus semantics and
/// tabular numerics. Non-numeric input is dropped silently (the draft text
/// reverts to the last-committed value on commit).
struct NumericDoubleField: View {

    let source: Double
    let width: CGFloat
    let onCommit: (Double) -> Void

    init(source: Double, width: CGFloat = 74, onCommit: @escaping (Double) -> Void) {
        self.source = source
        self.width = width
        self.onCommit = onCommit
    }

    var body: some View {
        CommitOnDefocusTextField(
            source: Self.format(source),
            font: .system(size: 12, design: .monospaced).monospacedDigit(),
            alignment: .trailing
        ) { text in
            guard let value = Double(text.trimmingCharacters(in: .whitespaces)) else {
                return
            }
            onCommit(value)
        }
        .frame(width: width)
    }

    private static func format(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}

/// Integer variant for things like font weight (100..900) and duration ms.
struct NumericIntField: View {

    let source: Int
    let width: CGFloat
    let onCommit: (Int) -> Void

    init(source: Int, width: CGFloat = 74, onCommit: @escaping (Int) -> Void) {
        self.source = source
        self.width = width
        self.onCommit = onCommit
    }

    var body: some View {
        CommitOnDefocusTextField(
            source: "\(source)",
            font: .system(size: 12, design: .monospaced).monospacedDigit(),
            alignment: .trailing
        ) { text in
            guard let value = Int(text.trimmingCharacters(in: .whitespaces)) else {
                return
            }
            onCommit(value)
        }
        .frame(width: width)
    }
}
