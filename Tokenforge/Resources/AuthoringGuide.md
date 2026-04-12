# Creating a Design System with Design Tokens and Hierarchy for an iOS App, and Conveying It to an LLM

Build it in two layers:

1. a **real design system for humans and code**
2. a **machine-readable spec for the LLM**

The mistake to avoid is handing the model screenshots and vague words like “clean” or “premium.” LLMs work much better when the system is expressed as named tokens, component rules, and hierarchy.

## 1) Start with foundations, not screens

For an iOS app, define the smallest reusable decisions first.

### Foundation tokens

These are raw values, with no product meaning yet.

- Color primitives  
  `blue-500`, `gray-900`, `white`, `black`
- Spacing scale  
  `4, 8, 12, 16, 20, 24, 32`
- Radius scale  
  `sm, md, lg, xl`
- Typography scale  
  font families, sizes, weights, line heights
- Elevation/shadow
- Stroke widths
- Motion durations and curves

Example:

```yaml
primitives:
  color:
    blue-500: "#2F6BFF"
    blue-600: "#1E56E6"
    gray-900: "#111827"
    gray-700: "#374151"
    gray-500: "#6B7280"
    gray-200: "#E5E7EB"
    white: "#FFFFFF"
    red-500: "#EF4444"

  spacing:
    0: 0
    1: 4
    2: 8
    3: 12
    4: 16
    5: 20
    6: 24
    8: 32

  radius:
    sm: 8
    md: 12
    lg: 16
    xl: 24

  typography:
    fontFamily:
      base: "SF Pro"
    fontSize:
      xs: 12
      sm: 14
      md: 16
      lg: 20
      xl: 24
      xxl: 32
    fontWeight:
      regular: 400
      medium: 500
      semibold: 600
      bold: 700
    lineHeight:
      tight: 1.2
      normal: 1.4
      relaxed: 1.6
```

## 2) Add semantic tokens

These are what the app actually means by those primitives.

Instead of telling engineers or the LLM “use blue-500,” tell them “use `color.action.primary.background`.”

Example:

```yaml
semantic:
  color:
    background:
      primary: "{primitives.color.white}"
      secondary: "#F9FAFB"
      inverse: "{primitives.color.gray-900}"

    text:
      primary: "{primitives.color.gray-900}"
      secondary: "{primitives.color.gray-700}"
      tertiary: "{primitives.color.gray-500}"
      inverse: "{primitives.color.white}"
      error: "{primitives.color.red-500}"

    action:
      primary:
        background: "{primitives.color.blue-500}"
        backgroundPressed: "{primitives.color.blue-600}"
        label: "{primitives.color.white}"

    border:
      subtle: "{primitives.color.gray-200}"

  spacing:
    screenPadding: "{primitives.spacing.4}"
    sectionGap: "{primitives.spacing.6}"
    itemGap: "{primitives.spacing.3}"

  radius:
    card: "{primitives.radius.lg}"
    button: "{primitives.radius.md}"

  type:
    titleLarge:
      size: "{primitives.typography.fontSize.xxl}"
      weight: "{primitives.typography.fontWeight.bold}"
      lineHeight: 1.15
    titleMedium:
      size: "{primitives.typography.fontSize.xl}"
      weight: "{primitives.typography.fontWeight.semibold}"
      lineHeight: 1.2
    body:
      size: "{primitives.typography.fontSize.md}"
      weight: "{primitives.typography.fontWeight.regular}"
      lineHeight: 1.4
    caption:
      size: "{primitives.typography.fontSize.sm}"
      weight: "{primitives.typography.fontWeight.regular}"
      lineHeight: 1.35
```

This is the level where both Swift code and an LLM become much easier to guide.

## 3) Define hierarchy explicitly

Hierarchy is where most design systems stay too fuzzy. Do not leave it as “clear visual hierarchy.” Turn it into rules.

For iOS, define hierarchy across:

- **screen level**
- **section level**
- **component level**
- **text level**
- **interaction level**

Example:

```yaml
hierarchy:
  screen:
    maxPrimaryActions: 1
    preferredStructure:
      - topBar
      - primaryContent
      - secondaryContent
      - persistentAction

  sections:
    order:
      - hero
      - keyInfo
      - supportingInfo
      - metadata
    spacingBetweenSections: "{semantic.spacing.sectionGap}"

  text:
    levels:
      h1: semantic.type.titleLarge
      h2: semantic.type.titleMedium
      body: semantic.type.body
      meta: semantic.type.caption
    rules:
      - Only one h1 per screen
      - h2 introduces a section
      - caption never used for primary actions
      - body is default for readable content

  emphasis:
    rules:
      - Use color emphasis only for interactive or status meaning
      - Use weight before color for text hierarchy
      - Never combine large size, bold weight, and accent color unless it is the primary focal element

  actions:
    priority:
      - primary
      - secondary
      - tertiary
    rules:
      - Only one primary action visible in a local area
      - Secondary actions should be visually quieter than primary
      - Destructive actions require explicit confirmation
```

That gives the LLM something it can actually follow.

## 4) Turn tokens into component contracts

Tokens alone are not enough. You also need component rules.

For each component, define:

- purpose
- variants
- allowed content
- states
- sizing
- composition rules
- accessibility rules
- do/don’t rules

Example button spec:

```yaml
components:
  button:
    variants:
      primary:
        background: "{semantic.color.action.primary.background}"
        foreground: "{semantic.color.action.primary.label}"
        radius: "{semantic.radius.button}"
      secondary:
        background: "transparent"
        foreground: "{semantic.color.text.primary}"
        border: "{semantic.color.border.subtle}"

    sizes:
      medium:
        height: 44
        horizontalPadding: "{primitives.spacing.4}"
        labelStyle: "{semantic.type.body}"

    states:
      default: {}
      pressed:
        background: "{semantic.color.action.primary.backgroundPressed}"
      disabled:
        opacity: 0.4

    rules:
      - Label should be 1 to 3 words
      - Use sentence case
      - Primary buttons appear once per action group
      - Do not place two primary buttons side by side
```

Example card spec:

```yaml
components:
  card:
    container:
      background: "{semantic.color.background.primary}"
      radius: "{semantic.radius.card}"
      padding: "{semantic.spacing.screenPadding}"
      borderColor: "{semantic.color.border.subtle}"

    structure:
      allowedSlots:
        - eyebrow
        - title
        - body
        - media
        - footerAction

    rules:
      - Title is required
      - Body is optional
      - Footer action should be tertiary unless card is the main CTA
```

## 5) Map this cleanly into Swift

For iOS, keep the runtime side simple and typed.

A common shape is:

- `PrimitiveTokens`
- `SemanticTokens`
- `TypographyTokens`
- `ComponentTokens`

Example sketch:

```swift
enum AppColor {
    static let backgroundPrimary = Color("backgroundPrimary")
    static let textPrimary = Color("textPrimary")
    static let actionPrimaryBackground = Color("actionPrimaryBackground")
}

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum AppRadius {
    static let button: CGFloat = 12
    static let card: CGFloat = 16
}

enum AppTextStyle {
    static let titleLarge = Font.system(size: 32, weight: .bold)
    static let titleMedium = Font.system(size: 24, weight: .semibold)
    static let body = Font.system(size: 16, weight: .regular)
    static let caption = Font.system(size: 14, weight: .regular)
}
```

For larger systems, generate these from JSON/YAML so design and code stay aligned.

## 6) What to give the LLM

Do not just provide “the design system.” Provide four things:

### A. Token dictionary

Machine-readable JSON or YAML.

### B. Component rules

How components are allowed to look and combine.

### C. Hierarchy rules

What should stand out, and what should recede.

### D. Output constraints

What kind of output you want from the LLM.

For example:

```yaml
llm_contract:
  task: "Generate iOS screen specs and SwiftUI-ready UI descriptions"
  output_format:
    - screen_name
    - purpose
    - layout_structure
    - components_used
    - text_content
    - applied_tokens
    - accessibility_notes
  hard_rules:
    - Use only tokens defined in this spec
    - Use only listed component variants
    - Follow hierarchy.text.rules
    - Follow hierarchy.actions.rules
    - Prefer iOS-native patterns
    - Minimum tap target is 44x44
    - Do not invent colors, spacing values, or type styles
```

## 7) Best format for LLM consumption

The most reliable format is:

- a short natural-language summary
- followed by structured YAML or JSON
- followed by examples

That works better than raw Figma export dumps.

A good package looks like this:

```text
System summary:
This app is calm, legible, and task-focused. The interface uses a restrained visual language with one primary accent color, strong spacing rhythm, and clear action hierarchy. Primary actions are rare and visually dominant. Information hierarchy relies on typography and spacing before color.

Structured spec:
[design-system YAML here]

Examples:
- Good screen example
- Bad screen example
- Good component usage
- Bad component usage
```

## 8) Give the LLM examples, not just rules

Rules help. Examples anchor behavior.

Include a few examples like:

### Good

```yaml
example_screen:
  name: "Payment Details"
  hierarchy:
    primaryFocus: "amount_due"
    secondaryFocus: "due_date"
    tertiaryFocus: "transaction_history"
  structure:
    - topBar
    - summaryCard
    - detailSection
    - primaryAction
  tokens:
    title: semantic.type.titleLarge
    body: semantic.type.body
    cardRadius: semantic.radius.card
```

### Bad

```yaml
anti_example:
  issues:
    - Two primary buttons in same section
    - Accent color used for decorative labels
    - Caption style used for important balance amount
    - More than one h1-equivalent title on the same screen
```

LLMs learn fast from contrast.

## 9) Tell the LLM what role it should play

You will get better results if the model knows whether it is supposed to act as:

- UI spec writer
- SwiftUI generator
- product designer
- design QA reviewer
- accessibility reviewer

Example prompt:

```text
You are designing iOS screens using the attached design system.
Use only defined tokens and components.
Do not invent styles.
Prioritize typography and spacing for hierarchy before using color.
Return:
1. screen structure
2. component list
3. token assignments
4. accessibility notes
5. SwiftUI pseudocode
```

## 10) Make the hierarchy inspectable

A very useful trick is to include explicit scoring or labels for emphasis.

Example:

```yaml
emphasis_scale:
  1: background or metadata
  2: supporting content
  3: normal body content
  4: section headers
  5: primary focal content
```

Then in screen specs:

```yaml
elements:
  - id: accountBalance
    emphasis: 5
    textStyle: semantic.type.titleLarge
  - id: dueDate
    emphasis: 4
    textStyle: semantic.type.titleMedium
  - id: helpText
    emphasis: 2
    textStyle: semantic.type.caption
```

That makes hierarchy much easier for an LLM to preserve.

## 11) What usually goes wrong

Common failure modes:

- tokens are too raw, with no semantic layer
- hierarchy is implied instead of written as rules
- components have visuals but no usage constraints
- dark mode and accessibility are omitted
- prompt allows the model to invent styles
- examples are missing
- design system is spread across prose, Figma, and code with no canonical source

## 12) A practical workflow for an iOS team

A solid setup is:

### Source of truth

One JSON or YAML spec for tokens and component rules.

### Design

Figma uses the same token names.

### Code

Swift or SwiftUI token layer generated from the spec.

### LLM input

A compact “LLM design contract” derived from the same spec, not handwritten each time.

### QA

Use the LLM as a reviewer too:

- identify token violations
- detect hierarchy violations
- detect component misuse
- suggest missing accessibility labels

## 13) Minimal schema to start with

If you want the smallest useful version, start with this:

```yaml
design_system:
  primitives:
    color: {}
    spacing: {}
    radius: {}
    typography: {}

  semantic:
    color: {}
    type: {}
    spacing: {}
    radius: {}

  hierarchy:
    text: {}
    actions: {}
    sections: {}
    emphasis: {}

  components:
    button: {}
    card: {}
    textField: {}
    listItem: {}
    navBar: {}

  accessibility:
    minTapTarget: 44
    minContrast: "WCAG AA"
    dynamicTypeSupport: true

  llm_contract:
    allowed_output: []
    hard_rules: []
```

## 14) Best single instruction to give the model

This one does a lot of work:

```text
Treat this design system as a strict API, not inspiration.
```

That changes the model from “creative stylist” to “constrained UI system consumer.”

## 15) Recommended final deliverables

Create these files:

- `design-tokens.json`
- `component-specs.yaml`
- `hierarchy-rules.yaml`
- `llm-design-contract.md`
- `swift-token-mapping.swift`

That gives you one system that serves design, engineering, and AI.
