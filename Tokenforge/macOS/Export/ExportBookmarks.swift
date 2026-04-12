//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import AppKit

/// Stores and resolves security-scoped bookmarks for per-document export
/// folders. Keyed by a UUID that's persisted on disk in
/// `TokenforgeSpec.lastExportBookmarkID` so the mapping survives document
/// renames and moves.
///
/// Kept as a plain `enum` — no observation, no actor — because bookmark
/// lookups happen from menu-command handlers on the main actor and the
/// storage is UserDefaults-backed. Per-user, per-machine; committing a
/// `.tokenforge` bundle to git does not leak one author's export path to
/// another because the bookmark itself lives in UserDefaults, not
/// `spec.json`.
///
@MainActor
enum ExportBookmarks {

    private static let keyPrefix = "io.apparata.Tokenforge.exportBookmark."

    // MARK: - Storage

    static func bookmarkData(for id: UUID) -> Data? {
        UserDefaults.standard.data(forKey: key(for: id))
    }

    static func setBookmarkData(_ data: Data?, for id: UUID) {
        let key = key(for: id)
        if let data {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - Resolution

    /// Resolves the stored bookmark to a directory `URL`. Returns `nil` if
    /// there is no bookmark, if resolution fails, if the bookmark is stale,
    /// or if the resolved URL is not a directory.
    ///
    /// The caller is responsible for pairing `startAccessingSecurityScopedResource()`
    /// and `stopAccessingSecurityScopedResource()` around the returned URL
    /// — see `withResolvedFolder(for:perform:)` for a helper that handles
    /// that lifecycle.
    static func resolve(_ id: UUID) -> URL? {
        guard let data = bookmarkData(for: id) else {
            return nil
        }
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                return nil
            }
            return url
        } catch {
            return nil
        }
    }

    /// Convenience that resolves the bookmark, scopes access around the
    /// closure, and returns whatever the closure returns. If resolution
    /// fails, the closure is not called and the function returns `nil`.
    static func withResolvedFolder<T>(for id: UUID, perform body: (URL) throws -> T) rethrows -> T? {
        guard let url = resolve(id) else {
            return nil
        }
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try body(url)
    }

    /// Creates a new security-scoped bookmark for `url` and stores it under
    /// `id`. Returns `true` on success.
    @discardableResult
    static func storeBookmark(for url: URL, id: UUID) -> Bool {
        do {
            let data = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            setBookmarkData(data, for: id)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Helpers

    private static func key(for id: UUID) -> String {
        keyPrefix + id.uuidString
    }
}
