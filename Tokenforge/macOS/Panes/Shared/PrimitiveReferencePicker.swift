//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// A `Menu`-backed picker that commits a new `TokenRef` when the user selects
/// one of the candidate primitives.
///
/// The label shows the **short tail** of the currently-bound reference
/// (e.g. `blue-500` for `{primitives.color.blue-500}`) so rows stay compact.
/// An optional leading swatch or preview glyph is built from the candidate
/// list when available.
///
struct PrimitiveReferencePicker: View {

    // MARK: - Config

    /// The reference currently bound (may be invalid / unresolvable — the
    /// picker still renders, with a warning badge).
    let currentReference: TokenRef

    /// Candidate primitives the user can pick from. The label is the
    /// primitive name; `preview` is an optional swatch or small visual shown
    /// next to the name.
    let candidates: [Candidate]

    let onCommit: (TokenRef) -> Void

    /// Builder for the `{...}` reference path from a bare primitive name.
    /// Passed in by the caller so the picker doesn't need to know the
    /// category.
    let referenceBuilder: (String) -> TokenRef

    // MARK: - Types

    struct Candidate: Identifiable, Hashable {
        let name: String
        let preview: CandidatePreview

        var id: String { name }
    }

    enum CandidatePreview: Hashable {
        case color(hex: String)
        case points(Double)
        case none
    }

    // MARK: - Body

    var body: some View {
        Menu {
            ForEach(candidates) { candidate in
                Button {
                    let newRef = referenceBuilder(candidate.name)
                    if newRef != currentReference {
                        onCommit(newRef)
                    }
                } label: {
                    switch candidate.preview {
                    case .color(let hex):
                        Label {
                            Text(candidate.name)
                        } icon: {
                            Circle().fill(Color(hex: hex) ?? .gray)
                        }
                    case .points(let value):
                        Text("\(candidate.name) · \(Self.formatted(value)) pt")
                    case .none:
                        Text(candidate.name)
                    }
                }
            }
        } label: {
            labelView
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.visible)
        .fixedSize()
    }

    @ViewBuilder
    private var labelView: some View {
        HStack(spacing: 6) {
            if let matchingCandidate, case .color(let hex) = matchingCandidate.preview {
                Circle()
                    .fill(Color(hex: hex) ?? .gray)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5))
            }
            Text(displayName)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(isResolvable ? Color.primary : Color.orange)
                .lineLimit(1)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(.separator, lineWidth: 0.5)
        )
    }

    // MARK: - Derived

    private var displayName: String {
        // Show the last path segment only, so a reference like
        // "{primitives.color.blue-500}" renders as "blue-500".
        guard let path = currentReference.path, let last = path.last else {
            return currentReference.rawValue
        }
        return last
    }

    private var matchingCandidate: Candidate? {
        candidates.first(where: { $0.name == displayName })
    }

    private var isResolvable: Bool {
        matchingCandidate != nil
    }

    private static func formatted(_ value: Double) -> String {
        value.rounded() == value
            ? String(format: "%.0f", value)
            : String(format: "%.2f", value)
    }
}
