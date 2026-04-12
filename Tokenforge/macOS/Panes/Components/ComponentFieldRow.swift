//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// A labeled row that wraps a `PrimitiveReferencePicker` for editing a
/// single `TokenRef` field inside a component contract.
///
/// Optional `detail` renders a trailing caption such as a resolved preview
/// value or a short remark.
///
struct ComponentFieldRow: View {

    let label: String
    let reference: TokenRef
    let candidates: [PrimitiveReferencePicker.Candidate]
    let referenceBuilder: (String) -> TokenRef
    let onCommit: (TokenRef) -> Void
    let detail: String?

    init(
        label: String,
        reference: TokenRef,
        candidates: [PrimitiveReferencePicker.Candidate],
        referenceBuilder: @escaping (String) -> TokenRef,
        onCommit: @escaping (TokenRef) -> Void,
        detail: String? = nil
    ) {
        self.label = label
        self.reference = reference
        self.candidates = candidates
        self.referenceBuilder = referenceBuilder
        self.onCommit = onCommit
        self.detail = detail
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)
            PrimitiveReferencePicker(
                currentReference: reference,
                candidates: candidates,
                onCommit: onCommit,
                referenceBuilder: referenceBuilder
            )
            if let detail {
                Text(detail)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }
}

/// An optional component field: shows a picker when bound, a "None" chip
/// plus a "Set" button when unbound.
struct OptionalComponentFieldRow: View {

    let label: String
    let reference: TokenRef?
    let candidates: [PrimitiveReferencePicker.Candidate]
    let referenceBuilder: (String) -> TokenRef
    let onCommit: (TokenRef?) -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)
            if let reference {
                PrimitiveReferencePicker(
                    currentReference: reference,
                    candidates: candidates,
                    onCommit: { new in onCommit(new) },
                    referenceBuilder: referenceBuilder
                )
                Button {
                    onCommit(nil)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear")
            } else {
                Text("None")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
                Button("Set") {
                    if let first = candidates.first {
                        onCommit(referenceBuilder(first.name))
                    }
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.accentColor)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }
}

/// Wrapper that shows a labeled numeric field alongside the component pickers.
struct ComponentNumericFieldRow: View {

    let label: String
    let value: Double
    let unit: String?
    let onCommit: (Double) -> Void

    init(label: String, value: Double, unit: String? = "pt", onCommit: @escaping (Double) -> Void) {
        self.label = label
        self.value = value
        self.unit = unit
        self.onCommit = onCommit
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)
            NumericDoubleField(source: value, width: 70, onCommit: onCommit)
            if let unit {
                Text(unit)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }
}
