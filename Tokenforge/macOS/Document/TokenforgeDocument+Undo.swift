//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

extension TokenforgeDocument {

    /// Applies a mutation to the spec and registers one undo/redo pair with the
    /// given `UndoManager`.
    ///
    /// Field-level coalescing (a single undo step per "type into a field" session)
    /// is implemented at the view layer by `CommitOnDefocusTextField`, which only
    /// calls this helper once — when the user commits by losing focus, pressing
    /// Enter, or pausing for one second. That keeps the undo stack readable
    /// without having to pop and rewrite registrations here.
    ///
    /// - Parameters:
    ///   - actionName: Text shown after "Undo"/"Redo" in the Edit menu.
    ///   - undoManager: The per-window undo manager, typically read from
    ///     `@Environment(\.undoManager)` by the calling view.
    ///   - mutate: A closure that mutates a draft copy of the spec.
    ///
    @MainActor
    func edit(
        actionName: String,
        undoManager: UndoManager?,
        mutate: (inout TokenforgeSpec) -> Void
    ) {
        let before = spec
        var draft = spec
        mutate(&draft)
        guard draft != before else {
            return
        }
        spec = draft
        registerUndoTransition(
            from: before,
            to: draft,
            actionName: actionName,
            undoManager: undoManager
        )
    }

    /// Registers a recursive undo/redo pair.
    ///
    /// When invoked by the undo manager, the closure restores the old state and
    /// re-registers the mirror transition — which, because we're inside an undo,
    /// is recorded as a redo. Redoing re-registers another undo, and so on.
    ///
    @MainActor
    private func registerUndoTransition(
        from oldState: TokenforgeSpec,
        to newState: TokenforgeSpec,
        actionName: String,
        undoManager: UndoManager?
    ) {
        guard let undoManager else {
            return
        }
        undoManager.setActionName(actionName)
        undoManager.registerUndo(withTarget: self) { target in
            target.spec = oldState
            target.registerUndoTransition(
                from: newState,
                to: oldState,
                actionName: actionName,
                undoManager: undoManager
            )
        }
    }
}
