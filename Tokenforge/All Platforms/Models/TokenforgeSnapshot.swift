//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Full state snapshot of a `TokenforgeDocument` used by
/// `ReferenceFileDocument` for save cycles and undo registration.
///
/// Earlier phases used `TokenforgeSpec` directly as the `Snapshot`
/// associated type. That worked while asset files were passed through
/// the `FileWrapper` untouched, but once the Fonts / Icons panes let
/// authors drop / delete / rename binary assets at runtime, the snapshot
/// has to include those bytes too — otherwise SwiftUI doesn't notice the
/// change and the document won't save.
///
/// Dictionary keys are filenames (with extension), values are the raw
/// file bytes. Equatable comparison is used by SwiftUI's dirtiness
/// tracking, so changing a single byte in any asset or spec field marks
/// the document as needing a save.
///
nonisolated struct TokenforgeSnapshot: Equatable, Sendable {
    var spec: TokenforgeSpec
    var fontData: [String: Data]
    var iconData: [String: Data]
}
