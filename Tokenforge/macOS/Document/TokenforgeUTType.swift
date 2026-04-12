//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {

    /// The `.tokenforge` package bundle type, declared via
    /// `UTExportedTypeDeclarations` in this target's `Info.plist`.
    ///
    /// Conforms to `com.apple.package` so Finder treats the bundle as opaque
    /// and SwiftUI's `ReferenceFileDocument` writes it as a directory via
    /// `FileWrapper`.
    ///
    nonisolated static let tokenforgeDocument = UTType(exportedAs: "io.apparata.tokenforge.document", conformingTo: .package)
}
