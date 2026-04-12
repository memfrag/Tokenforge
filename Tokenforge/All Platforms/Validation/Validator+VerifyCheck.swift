//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import os

#if DEBUG

extension Validator {

    /// Launch-time assertion that the bundled `DefaultSpec.json` is clean
    /// through the full validator — zero errors AND zero warnings.
    ///
    /// Phase 12 added more semantic entries and normalized names to
    /// kebab-case to pay down the unused-primitive warnings that shipped
    /// with earlier phases. This check locks that cleanup in so future
    /// edits to the seed can't silently regress it.
    ///
    /// On failure, prints the full problem list via `assertionFailure`
    /// so the first fix cycle catches every regression at once.
    ///
    static func verifyDefaultSpecIsClean() {
        let logger = Logger(subsystem: "io.apparata.Tokenforge", category: "ValidatorVerify")
        do {
            let spec = try TokenforgeSpec.loadDefaultFromBundle()
            let problems = Validator.validate(spec)
            if problems.isEmpty {
                logger.info("DefaultSpec validates clean (0 errors, 0 warnings).")
                return
            }
            let summary = ProblemSummary(problems: problems)
            let listing = problems.prefix(12).map { problem -> String in
                let detail = problem.detail.map { " — \($0)" } ?? ""
                return "• \(problem.severity.rawValue.uppercased()) \(problem.pane.label) · \(problem.breadcrumb) · \(problem.title)\(detail)"
            }.joined(separator: "\n")
            assertionFailure("""
                DefaultSpec is not clean: \(summary.errors) error(s), \(summary.warnings) warning(s).
                \(listing)
                """)
        } catch {
            assertionFailure("DefaultSpec validator check failed to load: \(error)")
        }
    }
}

#endif
