---
name: ios-test
description: Build, launch, and visually test iOS/SwiftUI apps in the Simulator using computer use. Automated screen navigation, crash log analysis, state testing (empty/error/loading), and memory leak detection. Use when you need to test an iOS app, run it in the Simulator, check for crashes, or verify UI flows.
---

# iOS Test Skill

## Overview

Use this skill to build an iOS/SwiftUI application, launch it in the Simulator, and visually test it using computer use. The skill navigates through every screen, screenshots each state, checks crash logs, and produces a structured test report — without writing a single line of test code.

## Options

- `--flow=<name>`: Test a specific user flow (e.g., onboarding, login, checkout)
- `--screen=<ViewName>`: Test only a specific screen
- `--device=<name>`: Choose a Simulator device (e.g., "iPhone 16", "iPhone SE")
- `--scheme=<name>`: Specify the Xcode scheme
- `--states`: Test empty, error, and loading states via launch arguments
- `--screenshot-all`: Screenshot every step
- `--performance`: Measure RAM per screen and check for memory leaks (skipped by default)

## Workflow

### 1) Project Discovery

- Find `.xcodeproj` or `.xcworkspace` in the working directory
  - Prefer `.xcworkspace` if it exists (CocoaPods/SPM workspace)
  - If multiple exist, ask the user which one to use
  - If none found, stop with an error
- List available schemes:
  ```bash
  xcodebuild -list -workspace MyApp.xcworkspace
  ```
  - Use `--scheme` if provided
  - If only one scheme exists, use it automatically
  - If multiple, ask the user

### 2) Simulator Selection (BEFORE build)

**IMPORTANT: Simulator must be selected BEFORE building. The build command uses the selected device name.**

- If `--device` is provided: find that device via `xcrun simctl list devices --json`
- If `--device` is not provided, check booted simulators:
  ```bash
  xcrun simctl list devices booted --json
  ```
  - **No booted simulator**: list available devices with `xcrun simctl list devices available --json`, suggest the best iPhone match, ask for confirmation, then boot it
  - **One booted simulator**: use it directly, no questions
  - **Multiple booted**: list them and ask the user which one to use

### 3) Build

- Build the selected scheme using the device chosen in step 2:
  ```bash
  xcodebuild build \
    -workspace MyApp.xcworkspace \
    -scheme MyApp \
    -destination 'platform=iOS Simulator,name=<SELECTED_DEVICE>' \
    -derivedDataPath ./DerivedData \
    2>&1
  ```
  **NEVER hardcode a device name like "iPhone 16". Always use the device selected in step 2.**
- If build fails: analyze errors, suggest fixes, and **STOP** — never proceed to testing with a failed build
- Report build warnings (but don't stop)

### 4) Install & Launch

- Find the built `.app` file:
  ```bash
  find ./DerivedData -name "*.app" -path "*/Debug-iphonesimulator/*" | head -1
  ```
- Get the bundle identifier:
  ```bash
  defaults read /path/to/MyApp.app/Info.plist CFBundleIdentifier
  ```
- Install and launch:
  ```bash
  xcrun simctl install booted /path/to/MyApp.app
  xcrun simctl launch booted com.example.MyApp
  ```

### 5) Visual Testing with Computer Use

**IMPORTANT: This phase requires the `computer-use` MCP server to be enabled.**

If computer use is not enabled, tell the user:
```
Computer use is not enabled. Required for visual testing.
Run /mcp and enable the computer-use server.
```

### 4.5) Accessibility Check (MANDATORY — DO NOT SKIP)

**This step is MANDATORY. After a successful build, BEFORE starting visual tests, this step MUST run. NEVER skip this step.**

1. Scan SwiftUI files in the project — look for `struct` ... `: View` patterns in `*.swift` files
2. Count interactive elements: `Button`, `TextField`, `SecureField`, `Toggle`, `Slider`, `Picker`, `DatePicker`, `NavigationLink`, `Image`, `.onTapGesture`
3. Check how many have `.accessibilityIdentifier()`
4. **ALWAYS ask the user (this question cannot be skipped):**

```
Accessibility Scan Result:
   Total interactive elements: XX
   With identifier: XX
   Missing identifier: XX

Identifiers help me find elements more reliably during testing.

Run /add-accessibility to add identifiers now?
  → Yes: adds identifiers, then continues to testing
  → No: I'll use coordinate-based testing (slower and more fragile)
```

5. **WAIT for the user's response.** Do not proceed to testing without an answer.
6. If yes:
   a. Run the full `/add-accessibility` workflow (scan, generate, apply)
   b. After identifiers are added, **REBUILD the app** (repeat step 3) — code changed, old build is stale
   c. If rebuild succeeds → reinstall & relaunch the app (repeat step 4)
   d. Then continue to testing
7. If no → continue with coordinate + visual analysis (no rebuild needed)

#### Default test (no arguments)

Discover and test all main screens:

1. **TabView present** → tap each tab, inspect each screen
2. **NavigationStack present** → tap each navigation link, go back
3. **On each screen** check:
   - Layout renders correctly (no overflow, overlapping, or empty areas)
   - Buttons are tappable
   - Scroll works and content is visible
   - Text is readable (not too small, not truncated)
4. Screenshot each screen

#### With `--flow=<name>`

Test the specified user flow:

- **onboarding**: swipe through onboarding screens, complete all steps
- **login**: fill email/password fields (test@example.com / Test1234), tap login, verify next screen
- **signup**: fill the registration form, tap signup
- **checkout**: navigate to cart, complete the payment flow
- **settings**: open settings, try each toggle/slider, go back
- Other flows: ask the user "What steps should I follow for this flow?"

#### With `--screen=<ViewName>`

Find and test only the specified screen. Navigate to it if needed.

### 6) State Testing (`--states` only)

Test different app states using launch arguments.

1. Check if the app supports state overrides via `CommandLine.arguments`:
   - Search SwiftUI files for `--show-empty-state`, `--show-error-state`, `--show-loading-state`
   - Search for `@AppStorage` or `UserDefaults` debug flags

2. If not found, ask the user:
   ```
   No state test support found. Would you like me to add launch argument
   handling to your @main App struct?

   A #if DEBUG block will be added supporting:
   - --show-empty-state
   - --show-error-state
   - --show-loading-state

   Only active in DEBUG builds. Add it?
   ```

3. If available, relaunch the app for each state:
   ```bash
   xcrun simctl terminate booted com.example.MyApp
   xcrun simctl launch booted com.example.MyApp --show-empty-state
   ```

   For each state verify:
   - **Empty state**: shows a meaningful message ("No content yet")
   - **Error state**: clear error message with a retry button
   - **Loading state**: loading indicator visible, UI not frozen
   - Screenshot each state

### 7) Crash Log Analysis

Check for crashes during and after testing:

```bash
xcrun simctl spawn booted log show --predicate 'process == "MyApp" AND messageType == 21' --last 5m
```

If a crash is found:
- Analyze the stack trace
- Identify which screen / action triggered it
- Find the relevant source code and report the likely cause

### 8) Performance Analysis (`--performance` only)

**ONLY run when `--performance` is provided. SKIP in default tests.**

Measure RAM usage per screen and check for memory leaks.

1. Find the app's PID:
   ```bash
   xcrun simctl spawn booted launchctl list | grep <BundleID>
   ```

2. Take a baseline measurement on launch:
   ```bash
   footprint -all <PID>
   ```

3. On each screen transition:
   - Navigate to the screen (via computer use)
   - Wait 2 seconds (let rendering complete)
   - Run `footprint -all <PID>`, record RAM
   - Calculate diff from previous screen

4. Check for leaks on back navigation:
   - Enter a screen → measure RAM
   - Go back → measure RAM
   - If delta > 5MB → flag as potential leak

5. Run a full leak scan at the end:
   ```bash
   leaks <PID>
   ```
   Report: leak count, object types, stack traces

6. Performance report format:
   ```
   Performance Report
   ━━━━━━━━━━━━━━━━━━━━━━━━━
   Baseline (launch):       42 MB

   Screen Transitions:
     HomeView:              45 MB (+3 MB)
     SettingsView:          52 MB (+7 MB)
     ProfileView:           68 MB (+16 MB) ⚠️
     → HomeView (back):     61 MB (-7 MB, 16 MB not released) ⚠️

   Memory Leaks:            2 found
     - SettingsViewModel: 1 leak (closure retain cycle?)
     - ImageCache: 1 leak

   ⚠️ High RAM: ProfileView (+16 MB jump)
   ⚠️ Potential Leak: 16 MB not released on return to HomeView
   ```

### 9) Test Report

Show a summary report when testing is complete:

```
iOS Test Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
App:         MyApp (com.example.MyApp)
Device:      iPhone 16 (iOS 18.2)
Scheme:      MyApp
Duration:    2m 34s

Screens Tested: 8
  ✅ HomeView - OK
  ✅ ProfileView - OK
  ⚠️ SettingsView - Toggle "notifications" not tappable
  ✅ OnboardingStep1 - OK
  ✅ OnboardingStep2 - OK
  ✅ OnboardingStep3 - OK
  ❌ CheckoutView - Crash (force unwrap on nil)
  ✅ SearchView - OK

Screenshots: 12 captured

Crashes: 1
  CheckoutView.swift:42 - Force unwrap on nil optional

UI Issues: 1
  SettingsView - notifications toggle not accessible

State Test Results:
  ✅ Empty State - OK
  ⚠️ Error State - Missing retry button
  ✅ Loading State - OK
```

## Important Rules

1. **NEVER proceed to testing if the build fails**
2. **Cannot do visual testing without computer use** — tell the user to enable it
3. Don't ask unnecessary questions about Simulator selection — use the one that's booted
4. Report every error and warning but **NEVER modify code without user approval**
5. Don't delete or modify the app's data during testing
6. Don't suggest adding launch arguments unless `--states` is provided
7. When a crash is detected, show the stack trace alongside the relevant source code
8. Save screenshots with meaningful names (e.g., `test-home-screen.png`)
9. **Do NOT close the Simulator** after testing — the user may want to continue
10. Provide brief status messages at each phase ("Building...", "Launching Simulator...", etc.)
