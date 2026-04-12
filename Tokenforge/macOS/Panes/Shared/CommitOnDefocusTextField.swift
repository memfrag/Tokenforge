//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// A text field that holds a local draft value while the user is typing and
/// only pushes a committed value to the caller when:
///
/// 1. the user presses Return / Tab (onSubmit), or
/// 2. the field loses focus, or
/// 3. one second elapses with no further edits.
///
/// Each commit triggers the `onCommit` closure exactly once, so callers can
/// wrap the commit in `TokenforgeDocument.edit(...)` and get one undo step per
/// editing session. Typing `FF3B30` into a hex field is one undo; switching
/// to the next field is one more.
///
/// External updates to `source` (e.g. from an undo) are reflected in the
/// draft only when the field is not currently focused, so user typing isn't
/// clobbered mid-edit.
///
struct CommitOnDefocusTextField: View {

    // MARK: - Config

    let placeholder: String
    let source: String
    let onCommit: (String) -> Void
    let font: Font
    let alignment: TextAlignment
    let axis: Axis
    let lineLimit: ClosedRange<Int>?

    init(
        placeholder: String = "",
        source: String,
        font: Font = .system(size: 12),
        alignment: TextAlignment = .leading,
        axis: Axis = .horizontal,
        lineLimit: ClosedRange<Int>? = nil,
        onCommit: @escaping (String) -> Void
    ) {
        self.placeholder = placeholder
        self.source = source
        self.font = font
        self.alignment = alignment
        self.axis = axis
        self.lineLimit = lineLimit
        self.onCommit = onCommit
    }

    // MARK: - State

    @State private var draft: String = ""
    @State private var idleTimer: Task<Void, Never>?
    @FocusState private var focused: Bool

    var body: some View {
        textField
            .textFieldStyle(.plain)
            .font(font)
            .multilineTextAlignment(alignment)
            .focused($focused)
            .onAppear {
                draft = source
            }
            .onChange(of: source) { _, newSource in
                if !focused {
                    draft = newSource
                }
            }
            .onChange(of: draft) { _, newDraft in
                guard focused else {
                    return
                }
                scheduleIdleCommit(newDraft)
            }
            .onChange(of: focused) { _, nowFocused in
                if !nowFocused {
                    idleTimer?.cancel()
                    idleTimer = nil
                    commitIfChanged()
                }
            }
            .onSubmit {
                idleTimer?.cancel()
                idleTimer = nil
                commitIfChanged()
            }
    }

    @ViewBuilder
    private var textField: some View {
        if let lineLimit, axis == .vertical {
            TextField(placeholder, text: $draft, axis: .vertical)
                .lineLimit(lineLimit)
        } else if axis == .vertical {
            TextField(placeholder, text: $draft, axis: .vertical)
        } else {
            TextField(placeholder, text: $draft)
        }
    }

    // MARK: - Commit plumbing

    private func scheduleIdleCommit(_ value: String) {
        idleTimer?.cancel()
        idleTimer = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else {
                return
            }
            commitIfChanged()
        }
    }

    private func commitIfChanged() {
        guard draft != source else {
            return
        }
        onCommit(draft)
    }
}
