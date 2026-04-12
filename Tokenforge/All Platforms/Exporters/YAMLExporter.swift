//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Hand-written YAML emitter for the subset of shapes Tokenforge actually
/// produces. No third-party dependency. Covers scalars, nested maps, and
/// lists of maps — which is everything the design system spec needs.
///
/// Emits two separate files:
/// - `component-specs.yaml` — the 12 component contracts
/// - `hierarchy-rules.yaml` — the hierarchy layer (screen structure, rules,
///   emphasis scale, type emphasis)
///
/// The tokens layer itself is distributed via `design-tokens.json` (the
/// canonical format) rather than YAML, because JSON is a strict subset of
/// YAML and engineering consumers typically prefer JSON for tokens.
///
nonisolated enum YAMLExporter {

    static func exportComponents(_ spec: TokenforgeSpec) -> Data {
        var builder = YAMLBuilder()
        builder.appendLine("components:")
        builder.indent {
            writeButton(spec.components.button, builder: &$0)
            writeCard(spec.components.card, builder: &$0)
            writeTextField(spec.components.textField, builder: &$0)
            writeListItem(spec.components.listItem, builder: &$0)
            writeNavBar(spec.components.navBar, builder: &$0)
            writeTabBar(spec.components.tabBar, builder: &$0)
            writeToolbar(spec.components.toolbar, builder: &$0)
            writeSegmentedControl(spec.components.segmentedControl, builder: &$0)
            writeToggle(spec.components.toggle, builder: &$0)
            writeAlert(spec.components.alert, builder: &$0)
            writeToastBanner(spec.components.toastBanner, builder: &$0)
            writeBadgeTag(spec.components.badgeTag, builder: &$0)
        }
        return Data(builder.result.utf8)
    }

    static func exportHierarchy(_ spec: TokenforgeSpec) -> Data {
        var builder = YAMLBuilder()
        let hierarchy = spec.hierarchy
        builder.appendLine("hierarchy:")
        builder.indent { builder in
            builder.appendLine("screenStructure:")
            builder.indent { builder in
                for section in hierarchy.screenStructure {
                    builder.appendLine("- \(YAMLBuilder.scalar(section))")
                }
            }
            builder.appendLine("maxPrimaryActionsPerArea: \(hierarchy.maxPrimaryActionsPerArea)")

            builder.appendLine("rules:")
            builder.indent { builder in
                for rule in hierarchy.rules {
                    builder.appendLine("- kind: \(rule.kind.rawValue)")
                    builder.indent { builder in
                        builder.appendLine("text: \(YAMLBuilder.scalar(rule.text))")
                    }
                }
            }

            builder.appendLine("emphasisScale:")
            builder.indent { builder in
                for level in hierarchy.emphasisScale {
                    builder.appendLine("- level: \(level.level)")
                    builder.indent { builder in
                        builder.appendLine("label: \(YAMLBuilder.scalar(level.label))")
                    }
                }
            }

            builder.appendLine("typeEmphasis:")
            builder.indent { builder in
                for mapping in hierarchy.typeEmphasis {
                    builder.appendLine("- typeStyle: \(YAMLBuilder.scalar(mapping.typeStyle.rawValue))")
                    builder.indent { builder in
                        builder.appendLine("level: \(mapping.level)")
                    }
                }
            }
        }
        return Data(builder.result.utf8)
    }

    // MARK: - Component writers

    private static func writeButton(_ button: ButtonSpec, builder: inout YAMLBuilder) {
        builder.appendLine("button:")
        builder.indent { b in
            b.appendLine("variants:")
            b.indent { b in
                writeButtonVariant("primary", variant: button.variants.primary, builder: &b)
                writeButtonVariant("secondary", variant: button.variants.secondary, builder: &b)
                writeButtonVariant("tertiary", variant: button.variants.tertiary, builder: &b)
            }
            b.appendLine("sizes:")
            b.indent { b in
                writeButtonSize("small", size: button.sizes.small, builder: &b)
                writeButtonSize("medium", size: button.sizes.medium, builder: &b)
                writeButtonSize("large", size: button.sizes.large, builder: &b)
            }
            b.appendLine("states:")
            b.indent { b in
                writeButtonState("pressed", state: button.states.pressed, builder: &b)
                writeButtonState("disabled", state: button.states.disabled, builder: &b)
                writeButtonState("focus", state: button.states.focus, builder: &b)
            }
            writeRules(button.rules, builder: &b)
        }
    }

    private static func writeButtonVariant(_ name: String, variant: ButtonVariant, builder: inout YAMLBuilder) {
        builder.appendLine("\(name):")
        builder.indent { b in
            b.appendLine("background: \(variant.background.rawValue)")
            b.appendLine("label: \(variant.label.rawValue)")
            if let border = variant.border {
                b.appendLine("border: \(border.rawValue)")
            }
            b.appendLine("radius: \(variant.radius.rawValue)")
        }
    }

    private static func writeButtonSize(_ name: String, size: ButtonSize, builder: inout YAMLBuilder) {
        builder.appendLine("\(name):")
        builder.indent { b in
            b.appendLine("heightPoints: \(size.heightPoints)")
            b.appendLine("horizontalPadding: \(size.horizontalPadding.rawValue)")
            b.appendLine("labelStyle: \(size.labelStyle.rawValue)")
        }
    }

    private static func writeButtonState(_ name: String, state: ButtonStateOverride, builder: inout YAMLBuilder) {
        builder.appendLine("\(name):")
        builder.indent { b in
            if let background = state.background {
                b.appendLine("background: \(background.rawValue)")
            }
            if let label = state.label {
                b.appendLine("label: \(label.rawValue)")
            }
            if let opacity = state.opacity {
                b.appendLine("opacity: \(opacity)")
            }
            if let focusRing = state.focusRing {
                b.appendLine("focusRing: \(focusRing.rawValue)")
            }
            if state.background == nil && state.label == nil && state.opacity == nil && state.focusRing == nil {
                b.appendLine("# no overrides")
            }
        }
    }

    private static func writeCard(_ card: CardSpec, builder: inout YAMLBuilder) {
        builder.appendLine("card:")
        builder.indent { b in
            b.appendLine("container:")
            b.indent { b in
                b.appendLine("background: \(card.container.background.rawValue)")
                b.appendLine("radius: \(card.container.radius.rawValue)")
                b.appendLine("padding: \(card.container.padding.rawValue)")
                if let border = card.container.borderColor {
                    b.appendLine("borderColor: \(border.rawValue)")
                }
            }
            b.appendLine("allowedSlots:")
            b.indent { b in
                for slot in card.allowedSlots {
                    b.appendLine("- \(YAMLBuilder.scalar(slot))")
                }
            }
            writeRules(card.rules, builder: &b)
        }
    }

    private static func writeTextField(_ field: TextFieldSpec, builder: inout YAMLBuilder) {
        builder.appendLine("textField:")
        builder.indent { b in
            b.appendLine("background: \(field.background.rawValue)")
            b.appendLine("labelColor: \(field.labelColor.rawValue)")
            b.appendLine("placeholderColor: \(field.placeholderColor.rawValue)")
            b.appendLine("borderColor: \(field.borderColor.rawValue)")
            b.appendLine("errorColor: \(field.errorColor.rawValue)")
            b.appendLine("radius: \(field.radius.rawValue)")
            writeRules(field.rules, builder: &b)
        }
    }

    private static func writeListItem(_ item: ListItemSpec, builder: inout YAMLBuilder) {
        builder.appendLine("listItem:")
        builder.indent { b in
            b.appendLine("background: \(item.background.rawValue)")
            b.appendLine("titleStyle: \(item.titleStyle.rawValue)")
            b.appendLine("subtitleStyle: \(item.subtitleStyle.rawValue)")
            if let leading = item.leadingIconColor {
                b.appendLine("leadingIconColor: \(leading.rawValue)")
            }
            if let trailing = item.trailingColor {
                b.appendLine("trailingColor: \(trailing.rawValue)")
            }
            b.appendLine("separatorColor: \(item.separatorColor.rawValue)")
            b.appendLine("rowHeightPoints: \(item.rowHeightPoints)")
            writeRules(item.rules, builder: &b)
        }
    }

    private static func writeNavBar(_ nav: NavBarSpec, builder: inout YAMLBuilder) {
        builder.appendLine("navBar:")
        builder.indent { b in
            b.appendLine("background: \(nav.background.rawValue)")
            b.appendLine("titleStyle: \(nav.titleStyle.rawValue)")
            if let large = nav.largeTitleStyle {
                b.appendLine("largeTitleStyle: \(large.rawValue)")
            }
            b.appendLine("leadingActionColor: \(nav.leadingActionColor.rawValue)")
            b.appendLine("trailingActionColor: \(nav.trailingActionColor.rawValue)")
            b.appendLine("supportsLargeTitle: \(nav.supportsLargeTitle)")
            writeRules(nav.rules, builder: &b)
        }
    }

    private static func writeTabBar(_ tab: TabBarSpec, builder: inout YAMLBuilder) {
        builder.appendLine("tabBar:")
        builder.indent { b in
            b.appendLine("background: \(tab.background.rawValue)")
            b.appendLine("itemSelectedColor: \(tab.itemSelectedColor.rawValue)")
            b.appendLine("itemUnselectedColor: \(tab.itemUnselectedColor.rawValue)")
            b.appendLine("labelStyle: \(tab.labelStyle.rawValue)")
            writeRules(tab.rules, builder: &b)
        }
    }

    private static func writeToolbar(_ tool: ToolbarSpec, builder: inout YAMLBuilder) {
        builder.appendLine("toolbar:")
        builder.indent { b in
            b.appendLine("background: \(tool.background.rawValue)")
            b.appendLine("actionColor: \(tool.actionColor.rawValue)")
            b.appendLine("separatorColor: \(tool.separatorColor.rawValue)")
            writeRules(tool.rules, builder: &b)
        }
    }

    private static func writeSegmentedControl(_ seg: SegmentedControlSpec, builder: inout YAMLBuilder) {
        builder.appendLine("segmentedControl:")
        builder.indent { b in
            b.appendLine("trackBackground: \(seg.trackBackground.rawValue)")
            b.appendLine("selectedBackground: \(seg.selectedBackground.rawValue)")
            b.appendLine("labelColor: \(seg.labelColor.rawValue)")
            b.appendLine("selectedLabelColor: \(seg.selectedLabelColor.rawValue)")
            b.appendLine("radius: \(seg.radius.rawValue)")
            writeRules(seg.rules, builder: &b)
        }
    }

    private static func writeToggle(_ toggle: ToggleSpec, builder: inout YAMLBuilder) {
        builder.appendLine("toggle:")
        builder.indent { b in
            b.appendLine("trackOn: \(toggle.trackOn.rawValue)")
            b.appendLine("trackOff: \(toggle.trackOff.rawValue)")
            b.appendLine("thumbColor: \(toggle.thumbColor.rawValue)")
            writeRules(toggle.rules, builder: &b)
        }
    }

    private static func writeAlert(_ alert: AlertSpec, builder: inout YAMLBuilder) {
        builder.appendLine("alert:")
        builder.indent { b in
            b.appendLine("surface: \(alert.surface.rawValue)")
            b.appendLine("titleStyle: \(alert.titleStyle.rawValue)")
            b.appendLine("bodyStyle: \(alert.bodyStyle.rawValue)")
            b.appendLine("actionColor: \(alert.actionColor.rawValue)")
            b.appendLine("destructiveActionColor: \(alert.destructiveActionColor.rawValue)")
            b.appendLine("radius: \(alert.radius.rawValue)")
            writeRules(alert.rules, builder: &b)
        }
    }

    private static func writeToastBanner(_ banner: ToastBannerSpec, builder: inout YAMLBuilder) {
        builder.appendLine("toastBanner:")
        builder.indent { b in
            b.appendLine("variants:")
            b.indent { b in
                writeBannerVariant("info", variant: banner.variants.info, builder: &b)
                writeBannerVariant("success", variant: banner.variants.success, builder: &b)
                writeBannerVariant("warning", variant: banner.variants.warning, builder: &b)
                writeBannerVariant("error", variant: banner.variants.error, builder: &b)
            }
            b.appendLine("radius: \(banner.radius.rawValue)")
            writeRules(banner.rules, builder: &b)
        }
    }

    private static func writeBannerVariant(_ name: String, variant: ToastBannerVariant, builder: inout YAMLBuilder) {
        builder.appendLine("\(name):")
        builder.indent { b in
            b.appendLine("background: \(variant.background.rawValue)")
            b.appendLine("label: \(variant.label.rawValue)")
            b.appendLine("iconColor: \(variant.iconColor.rawValue)")
        }
    }

    private static func writeBadgeTag(_ badge: BadgeTagSpec, builder: inout YAMLBuilder) {
        builder.appendLine("badgeTag:")
        builder.indent { b in
            b.appendLine("sizes:")
            b.indent { b in
                writeBadgeSize("small", size: badge.sizes.small, builder: &b)
                writeBadgeSize("medium", size: badge.sizes.medium, builder: &b)
            }
            b.appendLine("variants:")
            b.indent { b in
                writeBadgeVariant("neutral", variant: badge.variants.neutral, builder: &b)
                writeBadgeVariant("info", variant: badge.variants.info, builder: &b)
                writeBadgeVariant("success", variant: badge.variants.success, builder: &b)
                writeBadgeVariant("warning", variant: badge.variants.warning, builder: &b)
                writeBadgeVariant("error", variant: badge.variants.error, builder: &b)
            }
            b.appendLine("radius: \(badge.radius.rawValue)")
            writeRules(badge.rules, builder: &b)
        }
    }

    private static func writeBadgeSize(_ name: String, size: BadgeTagSize, builder: inout YAMLBuilder) {
        builder.appendLine("\(name):")
        builder.indent { b in
            b.appendLine("heightPoints: \(size.heightPoints)")
            b.appendLine("horizontalPadding: \(size.horizontalPadding.rawValue)")
            b.appendLine("labelStyle: \(size.labelStyle.rawValue)")
        }
    }

    private static func writeBadgeVariant(_ name: String, variant: BadgeTagVariant, builder: inout YAMLBuilder) {
        builder.appendLine("\(name):")
        builder.indent { b in
            b.appendLine("background: \(variant.background.rawValue)")
            b.appendLine("label: \(variant.label.rawValue)")
        }
    }

    private static func writeRules(_ rules: [ComponentRule], builder: inout YAMLBuilder) {
        builder.appendLine("rules:")
        builder.indent { b in
            if rules.isEmpty {
                b.appendLine("# no rules defined")
            }
            for rule in rules {
                b.appendLine("- kind: \(rule.kind.rawValue)")
                b.indent { b in
                    b.appendLine("text: \(YAMLBuilder.scalar(rule.text))")
                }
            }
        }
    }
}

// MARK: - YAMLBuilder

nonisolated struct YAMLBuilder {

    private var lines: [String] = []
    private var indentLevel: Int = 0

    var result: String { lines.joined(separator: "\n") + "\n" }

    mutating func appendLine(_ text: String) {
        lines.append(String(repeating: "  ", count: indentLevel) + text)
    }

    mutating func indent(_ work: (inout YAMLBuilder) -> Void) {
        indentLevel += 1
        work(&self)
        indentLevel -= 1
    }

    /// Escapes a scalar string so it's safe to emit on a single YAML line.
    /// Uses double-quoted form when the value contains control or special
    /// characters; otherwise emits unquoted.
    static func scalar(_ value: String) -> String {
        let needsQuoting = value.contains { c in
            c == ":" || c == "#" || c == "-" || c == "\"" || c == "\n" || c == "\r"
        } || value.isEmpty || value.first == " " || value.last == " "
        guard needsQuoting else {
            return value
        }
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        return "\"\(escaped)\""
    }
}
