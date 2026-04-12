//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

extension Color {

    /// Parses a hex string into a `Color`.
    ///
    /// Accepts `#RRGGBB`, `#RRGGBBAA`, `RRGGBB`, and `RRGGBBAA`. Returns
    /// `nil` on any malformed input; the caller is expected to fall back to
    /// a placeholder color and surface the problem elsewhere (a lint badge,
    /// a Problems pane entry, etc.).
    ///
    init?(hex: String) {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") {
            trimmed.removeFirst()
        }
        guard trimmed.count == 6 || trimmed.count == 8 else {
            return nil
        }
        guard let value = UInt64(trimmed, radix: 16) else {
            return nil
        }
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double
        if trimmed.count == 8 {
            alpha = Double((value & 0xFF000000) >> 24) / 255
            red = Double((value & 0x00FF0000) >> 16) / 255
            green = Double((value & 0x0000FF00) >> 8) / 255
            blue = Double(value & 0x000000FF) / 255
        } else {
            alpha = 1
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
        }
        self = Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
