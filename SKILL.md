---
name: swiftui-autotest-skill
description: AI-powered visual testing and accessibility setup for iOS/SwiftUI apps. Build, launch in Simulator, test with computer use, detect crashes, analyze memory leaks, and add accessibility identifiers — all from the terminal.
---

# SwiftUI Autotest Skill

Automated visual testing and accessibility identifier generation for iOS/SwiftUI applications using Claude Code's computer use.

## Included Skills

- **ios-test** — Build, launch in Simulator, visually test with computer use, crash log analysis, state testing (empty/error/loading), performance analysis (RAM/memory leaks)
- **add-accessibility** — Scan SwiftUI views and add missing accessibility identifiers using `{screen}-{type}-{name}` convention, flag Dynamic Type issues

## Quick Start

```bash
npx skills add yusufkaran/swiftui-autotest-skill
```

Then in your SwiftUI project:

```
/ios-test
/add-accessibility
```

See [README.md](README.md) for full documentation.
