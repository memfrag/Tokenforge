//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

enum SidebarPane {

    // MARK: Document

    case primitives
    case semantic
    case hierarchy
    case components
    case preview
    case contract
}

// MARK: - Protocol Conformances

extension SidebarPane: Equatable, Identifiable {
    var id: Self { self }
}
