# CLAUDE.md

## Project Overview

MarketTime is a native macOS menu bar application that displays real-time NYSE market status with a live countdown timer. Built entirely in Swift/SwiftUI with no external dependencies. Targets macOS 13.0+ (Ventura) and ships as a universal binary (arm64 + x86_64).

## Repository Structure

```
MarketTime/
├── Sources/
│   ├── main.swift                 # Entry point, NSApplication bootstrap
│   ├── AppDelegate.swift          # Menu bar UI, popover, event handling
│   ├── MarketTimer.swift          # Core market logic, NYSE holidays, countdown
│   ├── MarketStatusView.swift     # SwiftUI popover with retro terminal theme
│   └── SevenSegmentDisplay.swift  # Custom 7-segment LED display (Canvas)
├── Resources/
│   ├── Info.plist                 # App bundle config (com.markettime.app)
│   └── MarketTime.iconset/       # App icon assets
├── docs/
│   ├── index.html                # Project website
│   └── screenshot.png            # App screenshot
├── build.sh                      # Build script (compiles, signs, packages)
├── install.command               # One-click installer for end users
├── README.md                     # User-facing documentation
└── .gitignore
```

## Build System

No Xcode project — uses a shell-based build via `build.sh`:

```bash
./build.sh
```

This script:
1. Compiles all Swift sources separately for arm64 and x86_64
2. Merges into a universal binary with `lipo`
3. Converts the iconset to .icns via `iconutil`
4. Assembles the .app bundle in `build/MarketTime.app`
5. Ad-hoc code signs the app
6. Creates `MarketTime.zip` for distribution via `ditto`

**Prerequisites:** Xcode command-line tools (`swiftc`, `iconutil`, `lipo`, `codesign`).

**No test suite, linter, or CI/CD pipeline exists.**

## Key Architecture

- **AppDelegate** — Creates the NSStatusBar item, manages the popover, and owns the `MarketTimer` instance. Updates the menu bar icon text every second.
- **MarketTimer** — ObservableObject that determines market state (open, closed, holiday, weekend, early close) and computes countdown to the next state transition. Contains the full NYSE holiday calendar with observed-date logic and Easter/Good Friday calculation.
- **MarketStatusView** — SwiftUI view for the popover, styled as a retro green-on-black terminal. Shows status, countdown (via SevenSegmentDisplay), and dual clocks (EST + local).
- **SevenSegmentDisplay** — Custom SwiftUI Canvas renderer for 7-segment LED digit display.

## Conventions

- **Pure native Swift** — no package managers, no external dependencies. All frameworks (Cocoa, SwiftUI, Combine) are from the macOS SDK.
- **Bundle ID:** `com.markettime.app`, version `1.0.0`.
- **LSUIElement:** App runs as a menu bar agent (no Dock icon).
- **Timezone-aware:** Market logic uses `America/New_York`; UI shows both ET and local time.
- **Update loop:** 1-second timer via `DispatchQueue` for real-time countdown.

## Development Notes

- The build output goes to `build/` (gitignored).
- To test changes, run `./build.sh && open build/MarketTime.app`.
- The app requires macOS 13.0+ due to SwiftUI Canvas usage.
- Git branching: `main` is the primary remote branch.
