//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

nonisolated extension ComponentSet {

    /// Builds a fully-populated `ComponentSet` where every required field
    /// points at one of four caller-provided placeholder `TokenRef`s.
    ///
    /// Used by:
    /// - `TokenforgeDocument.emergencyComponentSet` — when `DefaultSpec.json`
    ///   fails to load and the app falls back to a structurally-valid empty
    ///   spec.
    /// - `DTCGImporter` — when an imported file set has primitives and
    ///   semantic tokens but no component contracts; we need a structurally
    ///   complete `ComponentSet` so the spec is editable, even though the
    ///   refs will surface as Problems until the author fixes them.
    ///
    /// All optional refs are left `nil` and all rule arrays empty.
    ///
    static func placeholder(
        color: TokenRef,
        spacing: TokenRef,
        radius: TokenRef,
        textStyle: TokenRef
    ) -> ComponentSet {
        let buttonVariant = ButtonVariant(
            background: color,
            label: color,
            border: nil,
            radius: radius
        )
        let buttonSize = ButtonSize(
            heightPoints: 44,
            horizontalPadding: spacing,
            labelStyle: textStyle
        )
        let textFieldSize = TextFieldSize(
            heightPoints: 44,
            horizontalPadding: spacing,
            labelStyle: textStyle
        )
        let badgeSize = BadgeTagSize(
            heightPoints: 22,
            horizontalPadding: spacing,
            labelStyle: textStyle
        )
        let bannerVariant = ToastBannerVariant(
            background: color,
            label: color,
            iconColor: color
        )
        let badgeVariant = BadgeTagVariant(background: color, label: color)

        return ComponentSet(
            button: ButtonSpec(
                variants: ButtonVariants(
                    primary: buttonVariant,
                    secondary: buttonVariant,
                    tertiary: buttonVariant
                ),
                sizes: ButtonSizes(
                    small: buttonSize,
                    medium: buttonSize,
                    large: buttonSize
                ),
                states: ButtonStates(
                    pressed: ButtonStateOverride(background: nil, label: nil, opacity: nil, focusRing: nil),
                    disabled: ButtonStateOverride(background: nil, label: nil, opacity: nil, focusRing: nil),
                    focus: ButtonStateOverride(background: nil, label: nil, opacity: nil, focusRing: nil)
                ),
                rules: []
            ),
            card: CardSpec(
                container: CardContainer(
                    background: color,
                    radius: radius,
                    padding: spacing,
                    borderColor: nil
                ),
                allowedSlots: [],
                rules: []
            ),
            textField: TextFieldSpec(
                background: color,
                labelColor: color,
                placeholderColor: color,
                borderColor: color,
                errorColor: color,
                radius: radius,
                sizes: TextFieldSizes(medium: textFieldSize, large: textFieldSize),
                states: TextFieldStates(
                    focused: TextFieldStateOverride(borderColor: nil, background: nil, opacity: nil),
                    disabled: TextFieldStateOverride(borderColor: nil, background: nil, opacity: nil),
                    error: TextFieldStateOverride(borderColor: nil, background: nil, opacity: nil)
                ),
                rules: []
            ),
            listItem: ListItemSpec(
                background: color,
                titleStyle: textStyle,
                subtitleStyle: textStyle,
                leadingIconColor: nil,
                trailingColor: nil,
                separatorColor: color,
                rowHeightPoints: 44,
                allowedSlots: [],
                rules: []
            ),
            navBar: NavBarSpec(
                background: color,
                titleStyle: textStyle,
                largeTitleStyle: nil,
                leadingActionColor: color,
                trailingActionColor: color,
                supportsLargeTitle: false,
                rules: []
            ),
            tabBar: TabBarSpec(
                background: color,
                itemSelectedColor: color,
                itemUnselectedColor: color,
                labelStyle: textStyle,
                rules: []
            ),
            toolbar: ToolbarSpec(
                background: color,
                actionColor: color,
                separatorColor: color,
                rules: []
            ),
            segmentedControl: SegmentedControlSpec(
                trackBackground: color,
                selectedBackground: color,
                labelColor: color,
                selectedLabelColor: color,
                radius: radius,
                rules: []
            ),
            toggle: ToggleSpec(
                trackOn: color,
                trackOff: color,
                thumbColor: color,
                rules: []
            ),
            alert: AlertSpec(
                surface: color,
                titleStyle: textStyle,
                bodyStyle: textStyle,
                actionColor: color,
                destructiveActionColor: color,
                radius: radius,
                rules: []
            ),
            toastBanner: ToastBannerSpec(
                variants: ToastBannerVariants(
                    info: bannerVariant,
                    success: bannerVariant,
                    warning: bannerVariant,
                    error: bannerVariant
                ),
                radius: radius,
                rules: []
            ),
            badgeTag: BadgeTagSpec(
                sizes: BadgeTagSizes(small: badgeSize, medium: badgeSize),
                variants: BadgeTagVariants(
                    neutral: badgeVariant,
                    info: badgeVariant,
                    success: badgeVariant,
                    warning: badgeVariant,
                    error: badgeVariant
                ),
                radius: radius,
                rules: []
            )
        )
    }
}
