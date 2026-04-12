//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// In-memory shape of a single DTCG (`.tokens.json`) file after parsing.
///
/// Tokenforge only handles the **Figma Variables flavor** of DTCG: each
/// file is a flat dictionary of token names at the root, every token has
/// a resolved `$value` literal even when it's an alias, and alias metadata
/// lives in `$extensions.com.figma.aliasData` instead of as a `{path}`
/// reference string.
///
/// `collectionName` and `modeName` are derived by `DTCGParser` from the
/// filename and the file-root `$extensions.com.figma.modeName` respectively.
///
nonisolated struct DTCGFile: Equatable, Sendable {
    var collectionName: String
    var modeName: String
    var sourceFilename: String
    var tokens: [DTCGToken]
}

/// One token from a DTCG file.
///
/// `literal` is always present (even on aliases — Figma stores the resolved
/// value alongside the alias metadata) and `aliasTargetName` is set iff the
/// token is an alias. The combination of literal + alias is what lets the
/// importer ignore Figma's collection naming and route by content.
///
nonisolated struct DTCGToken: Equatable, Sendable {
    var name: String
    var kind: DTCGType
    var literal: DTCGLiteral?
    var aliasTargetName: String?
}

nonisolated enum DTCGType: String, Equatable, Sendable {
    case color
    case number
    case unsupported
}

nonisolated enum DTCGLiteral: Equatable, Sendable {
    case color(hex: String)
    case number(Double)
}

// MARK: - Errors

nonisolated enum DTCGParseError: Error, CustomStringConvertible {
    case invalidJSON(filename: String)
    case rootNotObject(filename: String)

    var description: String {
        switch self {
        case .invalidJSON(let filename):
            return "Could not parse JSON in \(filename)."
        case .rootNotObject(let filename):
            return "DTCG file \(filename) is not a JSON object at the root."
        }
    }
}
