//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

// MARK: - ComponentSet

/// Fixed set of component contracts that Tokenforge ships with. The author
/// cannot add new component types; each property below is a bespoke struct
/// shaped to that component's fields.
nonisolated struct ComponentSet: Codable, Equatable, Sendable {
    var button: ButtonSpec
    var card: CardSpec
    var textField: TextFieldSpec
    var listItem: ListItemSpec
    var navBar: NavBarSpec
    var tabBar: TabBarSpec
    var toolbar: ToolbarSpec
    var segmentedControl: SegmentedControlSpec
    var toggle: ToggleSpec
    var alert: AlertSpec
    var toastBanner: ToastBannerSpec
    var badgeTag: BadgeTagSpec
}

// MARK: - Shared rule entry

/// Free-text rule with a kind tag, shared across component contracts.
nonisolated struct ComponentRule: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var kind: HierarchyRuleKind
    var text: String

    init(id: UUID = UUID(), kind: HierarchyRuleKind, text: String) {
        self.id = id
        self.kind = kind
        self.text = text
    }
}

// MARK: - Button

nonisolated struct ButtonSpec: Codable, Equatable, Sendable {
    var variants: ButtonVariants
    var sizes: ButtonSizes
    var states: ButtonStates
    var rules: [ComponentRule]
}

nonisolated struct ButtonVariants: Codable, Equatable, Sendable {
    var primary: ButtonVariant
    var secondary: ButtonVariant
    var tertiary: ButtonVariant
}

nonisolated struct ButtonVariant: Codable, Equatable, Sendable {
    var background: TokenRef
    var label: TokenRef
    var border: TokenRef?
    var radius: TokenRef
}

nonisolated struct ButtonSizes: Codable, Equatable, Sendable {
    var small: ButtonSize
    var medium: ButtonSize
    var large: ButtonSize
}

nonisolated struct ButtonSize: Codable, Equatable, Sendable {
    var heightPoints: Double
    var horizontalPadding: TokenRef
    var labelStyle: TokenRef
}

nonisolated struct ButtonStates: Codable, Equatable, Sendable {
    var pressed: ButtonStateOverride
    var disabled: ButtonStateOverride
    var focus: ButtonStateOverride
}

nonisolated struct ButtonStateOverride: Codable, Equatable, Sendable {
    var background: TokenRef?
    var label: TokenRef?
    var opacity: Double?
    var focusRing: TokenRef?
}

// MARK: - Card

nonisolated struct CardSpec: Codable, Equatable, Sendable {
    var container: CardContainer
    var allowedSlots: [String]
    var rules: [ComponentRule]
}

nonisolated struct CardContainer: Codable, Equatable, Sendable {
    var background: TokenRef
    var radius: TokenRef
    var padding: TokenRef
    var borderColor: TokenRef?
}

// MARK: - TextField

nonisolated struct TextFieldSpec: Codable, Equatable, Sendable {
    var background: TokenRef
    var labelColor: TokenRef
    var placeholderColor: TokenRef
    var borderColor: TokenRef
    var errorColor: TokenRef
    var radius: TokenRef
    var sizes: TextFieldSizes
    var states: TextFieldStates
    var rules: [ComponentRule]
}

nonisolated struct TextFieldSizes: Codable, Equatable, Sendable {
    var medium: TextFieldSize
    var large: TextFieldSize
}

nonisolated struct TextFieldSize: Codable, Equatable, Sendable {
    var heightPoints: Double
    var horizontalPadding: TokenRef
    var labelStyle: TokenRef
}

nonisolated struct TextFieldStates: Codable, Equatable, Sendable {
    var focused: TextFieldStateOverride
    var disabled: TextFieldStateOverride
    var error: TextFieldStateOverride
}

nonisolated struct TextFieldStateOverride: Codable, Equatable, Sendable {
    var borderColor: TokenRef?
    var background: TokenRef?
    var opacity: Double?
}

// MARK: - ListItem

nonisolated struct ListItemSpec: Codable, Equatable, Sendable {
    var background: TokenRef
    var titleStyle: TokenRef
    var subtitleStyle: TokenRef
    var leadingIconColor: TokenRef?
    var trailingColor: TokenRef?
    var separatorColor: TokenRef
    var rowHeightPoints: Double
    var allowedSlots: [String]
    var rules: [ComponentRule]
}

// MARK: - NavBar

nonisolated struct NavBarSpec: Codable, Equatable, Sendable {
    var background: TokenRef
    var titleStyle: TokenRef
    var largeTitleStyle: TokenRef?
    var leadingActionColor: TokenRef
    var trailingActionColor: TokenRef
    var supportsLargeTitle: Bool
    var rules: [ComponentRule]
}

// MARK: - TabBar

nonisolated struct TabBarSpec: Codable, Equatable, Sendable {
    var background: TokenRef
    var itemSelectedColor: TokenRef
    var itemUnselectedColor: TokenRef
    var labelStyle: TokenRef
    var rules: [ComponentRule]
}

// MARK: - Toolbar

nonisolated struct ToolbarSpec: Codable, Equatable, Sendable {
    var background: TokenRef
    var actionColor: TokenRef
    var separatorColor: TokenRef
    var rules: [ComponentRule]
}

// MARK: - SegmentedControl

nonisolated struct SegmentedControlSpec: Codable, Equatable, Sendable {
    var trackBackground: TokenRef
    var selectedBackground: TokenRef
    var labelColor: TokenRef
    var selectedLabelColor: TokenRef
    var radius: TokenRef
    var rules: [ComponentRule]
}

// MARK: - Toggle

nonisolated struct ToggleSpec: Codable, Equatable, Sendable {
    var trackOn: TokenRef
    var trackOff: TokenRef
    var thumbColor: TokenRef
    var rules: [ComponentRule]
}

// MARK: - Alert

nonisolated struct AlertSpec: Codable, Equatable, Sendable {
    var surface: TokenRef
    var titleStyle: TokenRef
    var bodyStyle: TokenRef
    var actionColor: TokenRef
    var destructiveActionColor: TokenRef
    var radius: TokenRef
    var rules: [ComponentRule]
}

// MARK: - ToastBanner

nonisolated struct ToastBannerSpec: Codable, Equatable, Sendable {
    var variants: ToastBannerVariants
    var radius: TokenRef
    var rules: [ComponentRule]
}

nonisolated struct ToastBannerVariants: Codable, Equatable, Sendable {
    var info: ToastBannerVariant
    var success: ToastBannerVariant
    var warning: ToastBannerVariant
    var error: ToastBannerVariant
}

nonisolated struct ToastBannerVariant: Codable, Equatable, Sendable {
    var background: TokenRef
    var label: TokenRef
    var iconColor: TokenRef
}

// MARK: - BadgeTag

nonisolated struct BadgeTagSpec: Codable, Equatable, Sendable {
    var sizes: BadgeTagSizes
    var variants: BadgeTagVariants
    var radius: TokenRef
    var rules: [ComponentRule]
}

nonisolated struct BadgeTagSizes: Codable, Equatable, Sendable {
    var small: BadgeTagSize
    var medium: BadgeTagSize
}

nonisolated struct BadgeTagSize: Codable, Equatable, Sendable {
    var heightPoints: Double
    var horizontalPadding: TokenRef
    var labelStyle: TokenRef
}

nonisolated struct BadgeTagVariants: Codable, Equatable, Sendable {
    var neutral: BadgeTagVariant
    var info: BadgeTagVariant
    var success: BadgeTagVariant
    var warning: BadgeTagVariant
    var error: BadgeTagVariant
}

nonisolated struct BadgeTagVariant: Codable, Equatable, Sendable {
    var background: TokenRef
    var label: TokenRef
}
