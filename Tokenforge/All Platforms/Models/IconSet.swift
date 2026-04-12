//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Curated list of icon-name references the author has chosen for this
/// design system. Today this is just SF Symbol names — future phases
/// may add per-file metadata for bundled icons here too.
///
/// Unlike `TokenforgeDocument.iconData` (which holds raw bytes for
/// author-dropped PNG / PDF / SVG files), `IconSet` holds **references**
/// to icons that live outside the bundle: SF Symbols are a system
/// library available on every Apple platform, so we only need to record
/// their names.
///
/// Stored in `TokenforgeSpec.iconSet` with a default empty value so the
/// Codable synthesis on `TokenforgeSpec` can decode existing schema-v1
/// files that don't have the key — the default kicks in when the key is
/// missing, no custom `init(from:)` required.
///
nonisolated struct IconSet: Codable, Equatable, Sendable {

    var sfSymbols: [SFSymbolEntry]

    init(sfSymbols: [SFSymbolEntry] = []) {
        self.sfSymbols = sfSymbols
    }
}

/// One SF Symbol the author wants to reference from their design system.
///
/// `name` is the identifier you'd pass to `Image(systemName:)` —
/// `"heart.fill"`, `"chevron.right"`, `"xmark.circle.fill"`. `caption`
/// is an optional author-chosen label surfaced in the Icons pane and
/// the LLM contract.
///
/// Identified by `name` so SwiftUI `ForEach` and validation dedupe
/// on the same identity.
///
nonisolated struct SFSymbolEntry: Codable, Equatable, Sendable, Identifiable {

    var name: String
    var caption: String

    var id: String { name }

    init(name: String, caption: String = "") {
        self.name = name
        self.caption = caption
    }
}
