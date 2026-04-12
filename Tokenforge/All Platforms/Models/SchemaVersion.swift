//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// The schema version this build of Tokenforge understands.
///
/// `.tokenforge` bundles carry a `schemaVersion` integer in `spec.json`. Tokenforge
/// refuses to open files whose version does not match this constant. Bumping this
/// value requires all collaborators to update to a compatible build — there is no
/// migration path by design.
///
nonisolated enum SchemaVersion {

    /// Current schema version.
    static let current: Int = 1
}
