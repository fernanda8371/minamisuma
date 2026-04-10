# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MinamisumaCapitalOne** is an iOS app built with SwiftUI and SwiftData. It targets iOS 26.2 and uses the modern `@main` SwiftUI lifecycle (no AppDelegate/SceneDelegate).

## Build & Run

Open `MinamisumaCapitalOne.xcodeproj` in Xcode. No external dependencies (no CocoaPods, SPM, or Carthage).

To build from the command line:
```bash
xcodebuild -project MinamisumaCapitalOne.xcodeproj -scheme MinamisumaCapitalOne -destination 'platform=iOS Simulator,name=iPhone 16' build
```

To run tests:
```bash
# Unit tests
xcodebuild test -project MinamisumaCapitalOne.xcodeproj -scheme MinamisumaCapitalOne -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MinamisumaCapitalOneTests

# Single test
xcodebuild test -project MinamisumaCapitalOne.xcodeproj -scheme MinamisumaCapitalOne -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MinamisumaCapitalOneTests/MinamisumaCapitalOneTests/exampleMethod
```

## Architecture

The project follows an MVC folder structure with SwiftUI+SwiftData:

- `Models/` — SwiftData `@Model` classes. `Item.swift` is the base template model.
- `Views/` — SwiftUI view files.
- `Controlers/` — Controller logic (note the typo in folder name).
- `MinamisumaCapitalOneApp.swift` — App entry point; sets up the SwiftData `ModelContainer`.
- `ContentView.swift` — Root view.

**Data layer:** SwiftData with `@Model`, `@Query`, and `@Environment(\.modelContext)`. The `ModelContainer` is configured at the app level in `MinamisumaCapitalOneApp` and injected into the view hierarchy automatically.

**Testing:** Uses the Swift Testing framework (`import Testing`, `@Test` attribute) — not XCTest. Write new tests using `@Test` functions, not `XCTestCase` subclasses.

## Current State

The project is in early development. Most folders have placeholder files. The `ScamProtect` branch is the current working branch.
