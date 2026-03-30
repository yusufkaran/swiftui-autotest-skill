---
name: add-accessibility
description: Scan SwiftUI views and add missing accessibility identifiers using a consistent {screen}-{type}-{name} naming convention. Also flags Dynamic Type compatibility issues. Use when you need to add accessibility support, make views testable, add VoiceOver labels, or prepare for UI testing.
---

# Add Accessibility Skill

## Overview

Use this skill to scan all SwiftUI files in a project, find interactive elements missing accessibility identifiers, and add them using a consistent `{screen}-{type}-{name}` naming convention. Also flags Dynamic Type compatibility issues without auto-fixing them.

## Options

- `--dry-run`: Don't modify files, only report what would be changed
- `--path=<path>`: Scan only the specified directory (default: all SwiftUI files)
- `--verbose`: Log each identifier added in detail

## Workflow

### 1) Scan & Analyze

1. Find all `*.swift` files in the project
2. Filter to files containing SwiftUI views (`struct X: View`, `#Preview`, etc.)
3. In each file, detect these interactive elements:
   - `Button` — buttons
   - `TextField` and `SecureField` — input fields
   - `Image` — images
   - `Toggle` — toggle switches
   - `Slider` — sliders
   - `Picker` — pickers
   - `DatePicker` — date pickers
   - `NavigationLink` — navigation links
   - `TabView` tab items
   - `.onTapGesture` views — tap gesture elements
   - `Link` — external links

4. For each element, check existing accessibility state:
   - Has `.accessibilityIdentifier()`? → **SKIP**
   - Has `.accessibilityLabel()`? → **SKIP**
   - If either exists, do not touch it

### 2) Generate Identifiers

Naming convention: `{screen}-{type}-{name}`

**Screen name**: derived from the filename
- `LoginView.swift` → `login`
- `OnboardingStepView.swift` → `onboarding-step`
- `HomeTabView.swift` → `home-tab`
- Remove `View` suffix, convert camelCase to kebab-case

**Type**: based on the element type

| SwiftUI Element | Type |
|----------------|------|
| Button | `button` |
| TextField | `textfield` |
| SecureField | `securefield` |
| Image | `image` |
| Toggle | `toggle` |
| Slider | `slider` |
| Picker | `picker` |
| DatePicker | `datepicker` |
| NavigationLink | `navlink` |
| Link | `link` |
| .onTapGesture view | `tap` |
| TabView item | `tab` |

**Name**: derived from the element's content
- `Button("Continue")` → `continue`
- `TextField("Email", ...)` → `email`
- `Image(systemName: "gear")` → `gear`
- `Image("hero-banner")` → `hero-banner`
- `Toggle("Notifications", ...)` → `notifications`
- No content or too complex → number sequentially (`button-1`, `button-2`)

**Example results:**
```
login-button-continue
login-textfield-email
login-securefield-password
onboarding-image-hero-banner
settings-toggle-notifications
home-tab-profile
```

### 3) Apply Changes

Add `.accessibilityIdentifier("generated-id")` to each element missing one:

```swift
// BEFORE
Button("Continue") {
    viewModel.proceed()
}

// AFTER
Button("Continue") {
    viewModel.proceed()
}
.accessibilityIdentifier("login-button-continue")
```

**For Images**, also add `accessibilityLabel` (for VoiceOver):

```swift
// BEFORE
Image(systemName: "gear")

// AFTER
Image(systemName: "gear")
    .accessibilityIdentifier("settings-image-gear")
    .accessibilityLabel("Settings")
```

**For onTapGesture views**, mark as accessibility elements:

```swift
// BEFORE
HStack {
    Image("avatar")
    Text(user.name)
}
.onTapGesture { showProfile() }

// AFTER
HStack {
    Image("avatar")
    Text(user.name)
}
.onTapGesture { showProfile() }
.accessibilityElement(children: .combine)
.accessibilityIdentifier("profile-tap-user-row")
.accessibilityAddTraits(.isButton)
```

### 4) Dynamic Type Check

Check Text elements for Dynamic Type compatibility:

1. **Flag** (report as warnings, do NOT auto-fix):
   - `Text` without `.lineLimit()` when the content could be long
   - `Text` without `.minimumScaleFactor()` in constrained areas
   - `.font(.system(size: XX))` with hardcoded font sizes instead of dynamic fonts like `.font(.title)`, `.font(.body)`

2. **Report format:**
```
⚠️ Dynamic Type Warnings:
  LoginView.swift:42 - Text("Welcome back...") → missing lineLimit or minimumScaleFactor
  LoginView.swift:58 - Text(...).font(.system(size: 14)) → consider using dynamic font (.body, .caption, etc.)
  SettingsView.swift:23 - Text(longString) → missing lineLimit, risk of overflow with large text
```

### 5) Summary Report

Show a summary when the scan is complete:

```
✅ Accessibility Scan Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files scanned:     24
Elements found:    87
Already present:   31 (skipped)
Newly added:       56
  - Button:        18
  - TextField:      8
  - Image:         12
  - Toggle:         6
  - Other:         12

⚠️ Dynamic Type Warnings: 7
  (details above)

Pattern: {screen}-{type}-{name}
```

## Important Rules

1. **NEVER modify or remove existing accessibility modifiers**
2. **NEVER change the view's functionality or appearance**
3. Only add `.accessibilityIdentifier()`, `.accessibilityLabel()`, `.accessibilityElement()`, `.accessibilityAddTraits()`
4. Do NOT wrap in `#if DEBUG` — identifiers must be in production too (for real accessibility / VoiceOver)
5. If unsure about a name, use `{screen}-{type}-{index}` format and flag it in verbose mode
6. Dynamic Type warnings are REPORT ONLY — do not auto-fix, leave it to the user
7. In `--dry-run` mode, do not modify any files — only show the plan
8. After modifying each file, run a compile check — if a syntax error is introduced, revert
