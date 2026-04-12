//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Root of a Tokenforge design system spec. Serialized to `spec.json` inside the
/// `.tokenforge` package bundle.
///
/// Tokenforge opens and saves this type verbatim; it is the canonical, lossless
/// on-disk form. Exported files (JSON, YAML, Swift, markdown, asset catalog)
/// are derived views, not alternative formats.
///
nonisolated struct TokenforgeSpec: Codable, Equatable, Sendable {

    /// Matches `SchemaVersion.current`. Mismatch on load is a hard error.
    var schemaVersion: Int

    var meta: SpecMeta
    var primitives: Primitives
    var semantic: SemanticTokens
    var hierarchy: HierarchyRules
    var components: ComponentSet
    var accessibility: AccessibilityRules
    var llmContract: LLMContractOverrides
    var examples: ExtraExamples

    /// Curated list of icon-name references (SF Symbols) the author has
    /// chosen for this design system. Decoded with `decodeIfPresent` so
    /// existing schema-v1 `.tokenforge` files (and `DefaultSpec.json`)
    /// saved before this field existed still open cleanly.
    var iconSet: IconSet = IconSet()

    /// Opaque UUID used to key a per-document export-folder security-scoped
    /// bookmark in `AppSettings`. Stored in `spec.json` so the mapping survives
    /// when the user renames or moves the bundle.
    var lastExportBookmarkID: UUID?

    // Synthesized Codable does NOT use Swift property defaults during
    // decoding — it always calls `decode(_:forKey:)` and throws on a
    // missing key. To allow `iconSet` to be optional in old files we
    // hand-roll the decoder, falling back to `decodeIfPresent` for that
    // single key while leaving everything else unchanged.

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case meta
        case primitives
        case semantic
        case hierarchy
        case components
        case accessibility
        case llmContract
        case examples
        case iconSet
        case lastExportBookmarkID
    }

    init(
        schemaVersion: Int,
        meta: SpecMeta,
        primitives: Primitives,
        semantic: SemanticTokens,
        hierarchy: HierarchyRules,
        components: ComponentSet,
        accessibility: AccessibilityRules,
        llmContract: LLMContractOverrides,
        examples: ExtraExamples,
        iconSet: IconSet = IconSet(),
        lastExportBookmarkID: UUID? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.meta = meta
        self.primitives = primitives
        self.semantic = semantic
        self.hierarchy = hierarchy
        self.components = components
        self.accessibility = accessibility
        self.llmContract = llmContract
        self.examples = examples
        self.iconSet = iconSet
        self.lastExportBookmarkID = lastExportBookmarkID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        self.meta = try container.decode(SpecMeta.self, forKey: .meta)
        self.primitives = try container.decode(Primitives.self, forKey: .primitives)
        self.semantic = try container.decode(SemanticTokens.self, forKey: .semantic)
        self.hierarchy = try container.decode(HierarchyRules.self, forKey: .hierarchy)
        self.components = try container.decode(ComponentSet.self, forKey: .components)
        self.accessibility = try container.decode(AccessibilityRules.self, forKey: .accessibility)
        self.llmContract = try container.decode(LLMContractOverrides.self, forKey: .llmContract)
        self.examples = try container.decode(ExtraExamples.self, forKey: .examples)
        self.iconSet = try container.decodeIfPresent(IconSet.self, forKey: .iconSet) ?? IconSet()
        self.lastExportBookmarkID = try container.decodeIfPresent(UUID.self, forKey: .lastExportBookmarkID)
    }
}

// MARK: - Errors

nonisolated enum TokenforgeSpecError: Error, CustomStringConvertible {
    case schemaVersionMismatch(found: Int, expected: Int)
    case resourceMissing(name: String)
    case decoding(underlying: Error)

    var description: String {
        switch self {
        case .schemaVersionMismatch(let found, let expected):
            return "Schema version mismatch: file is v\(found), this build understands v\(expected)."
        case .resourceMissing(let name):
            return "Bundle resource missing: \(name)"
        case .decoding(let underlying):
            return "Failed to decode TokenforgeSpec: \(underlying)"
        }
    }
}

// MARK: - Bundle loading

nonisolated extension TokenforgeSpec {

    /// Loads `DefaultSpec.json` from the main bundle, decodes it, and enforces
    /// the `schemaVersion` match. This is the seed used for new documents.
    static func loadDefaultFromBundle() throws -> TokenforgeSpec {
        guard let url = Bundle.main.url(forResource: "DefaultSpec", withExtension: "json") else {
            throw TokenforgeSpecError.resourceMissing(name: "DefaultSpec.json")
        }
        let data = try Data(contentsOf: url)
        return try decode(from: data)
    }

    /// Decodes a spec from raw JSON data and enforces strict schema version match.
    static func decode(from data: Data) throws -> TokenforgeSpec {
        let decoder = JSONDecoder()
        do {
            let spec = try decoder.decode(TokenforgeSpec.self, from: data)
            guard spec.schemaVersion == SchemaVersion.current else {
                throw TokenforgeSpecError.schemaVersionMismatch(
                    found: spec.schemaVersion,
                    expected: SchemaVersion.current
                )
            }
            return spec
        } catch let error as TokenforgeSpecError {
            throw error
        } catch {
            throw TokenforgeSpecError.decoding(underlying: error)
        }
    }

    /// Encodes the spec to pretty-printed, key-sorted JSON suitable for writing
    /// to `spec.json` or diffing in git.
    func encodeJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}
