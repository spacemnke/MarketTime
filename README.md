# MarketTime

A retro terminal-styled macOS menu bar app that shows the NYSE market status with a live countdown timer.

![MarketTime Screenshot](screenshot.png)

## Features

- **Menu bar display** — Shows market open/closed status with a live countdown
- **Click to expand** — Full popover with countdown, local time, EST time, and next trading day
- **Holiday-aware** — Handles all NYSE holidays including observed dates and Good Friday
- **Dual timezone** — Shows both your local time and Eastern Time for traders outside EST
- **Retro terminal UI** — Green-on-black CRT aesthetic with glow effects

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode Command Line Tools (`xcode-select --install`)

## Build & Run

```bash
cd MarketTime
./build.sh
open build/MarketTime.app
```

## Install

After building, copy to Applications:

```bash
cp -r build/MarketTime.app /Applications/
```

## Share

Zip the built app and send it to anyone on macOS 13+:

```bash
cd build
zip -r MarketTime.zip MarketTime.app
```

Recipients just unzip and double-click. On first launch, they may need to right-click > Open to bypass Gatekeeper (since the app is ad-hoc signed).

## Start at Login

To launch automatically when you log in:

1. Open **System Settings** > **General** > **Login Items**
2. Click **+** and select **MarketTime.app**

## NYSE Holiday Calendar

The app automatically accounts for all NYSE market holidays:

- New Year's Day
- Martin Luther King Jr. Day
- Presidents' Day
- Good Friday
- Memorial Day
- Juneteenth
- Independence Day
- Labor Day
- Thanksgiving Day
- Christmas Day

Observed holiday rules (Saturday → Friday, Sunday → Monday) are handled automatically.
