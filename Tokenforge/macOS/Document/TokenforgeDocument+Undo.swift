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

    /// Registers a recursive undo/redo pair for spec mutations.
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

    // MARK: - Asset editing

    /// Mutable draft of the document's asset state. Used by `editAssets`
    /// so the caller can add / delete / rename font and icon files in one
    /// atomic closure and have the whole transition captured as a single
    /// undo step.
    struct AssetsDraft: Equatable {
        var fontData: [String: Data]
        var iconData: [String: Data]
    }

    /// Applies a mutation to the font + icon dictionaries and registers
    /// one undo/redo pair. Parallel to `edit(...)` but scoped to asset
    /// state so drops, deletes, and renames in the Fonts / Icons panes
    /// become single undoable operations.
    @MainActor
    func editAssets(
        actionName: String,
        undoManager: UndoManager?,
        mutate: (inout AssetsDraft) -> Void
    ) {
        let before = AssetsDraft(fontData: fontData, iconData: iconData)
        var draft = before
        mutate(&draft)
        guard draft != before else {
            return
        }
        fontData = draft.fontData
        iconData = draft.iconData
        registerAssetsUndoTransition(
            from: before,
            to: draft,
            actionName: actionName,
            undoManager: undoManager
        )
    }

    /// Registers a recursive undo/redo pair for asset-state mutations.
    /// Same recursive pattern as `registerUndoTransition`.
    @MainActor
    private func registerAssetsUndoTransition(
        from oldState: AssetsDraft,
        to newState: AssetsDraft,
        actionName: String,
        undoManager: UndoManager?
    ) {
        guard let undoManager else {
            return
        }
        undoManager.setActionName(actionName)
        undoManager.registerUndo(withTarget: self) { target in
            target.fontData = oldState.fontData
            target.iconData = oldState.iconData
            target.registerAssetsUndoTransition(
                from: newState,
                to: oldState,
                actionName: actionName,
                undoManager: undoManager
            )
        }
    }
}
