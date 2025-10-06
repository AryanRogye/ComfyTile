# Repository Guidelines

## Project Structure & Module Organization
Source lives in `ComfyTile/`, grouped by responsibility so you can navigate by feature rather than file type.
- `App/` holds `AppDelegate` and startup glue; update it when wiring new services.
- `MenuBar/` contains SwiftUI menu bar scenes; keep UI-only code here.
- `Coordinators/` manage cross-component flows like hotkeys.
- `Services/` host macOS integrations (e.g. `PermissionService`); isolate all sandbox or API calls here.
- `Extensions/` and `Utils/` provide shared helpers—keep extensions focused and stateless.
- `Assets.xcassets` and `ComfyTile.entitlements` store UI assets and capability definitions.

## Build, Test, and Development Commands
- `open ComfyTile.xcodeproj` launches Xcode with the app target.
- `xcodebuild -scheme ComfyTile -configuration Debug build` performs a CI-friendly build.
- `xcodebuild test -scheme ComfyTileTests -destination 'platform=macOS'` runs the XCTest target after you add it to the project.
- `swift package resolve` (from within Xcode) refreshes Swift Package Manager dependencies such as `KeyboardShortcuts`.

## Coding Style & Naming Conventions
Use Swift 5 defaults: 4-space indentation, trailing commas in multiline lists, and whitespace around control-flow keywords. Name types with `PascalCase`, properties and functions with descriptive `camelCase`, and prefer protocol-oriented extensions. Co-locate private helpers in `fileprivate` extensions and group view code with `// MARK:` sections.

## Testing Guidelines
Adopt XCTest with a sibling `ComfyTileTests/` group. Name files `<Feature>Tests.swift` and methods `test_<Scenario>_<Expectation>()`. Stub macOS APIs via protocols in `Services/` to keep tests deterministic. Enforce coverage on new code by adding focused tests before opening a pull request and ensure `xcodebuild test` passes locally.

## Commit & Pull Request Guidelines
Follow the existing history’s concise, lower-case summaries (≤50 chars) and present-tense verbs, e.g. `add hotkey coordinator`. Reference issues in the body. Pull requests should explain the change, note affected directories, list validation steps (build, tests), and include screenshots or screen recordings for UI tweaks. Request a review from another contributor before merging.

## Security & Configuration Notes
`ComfyTile.entitlements` and `PermissionService` manage Accessibility privileges—verify System Settings permissions after new capability changes. Avoid checking personal signing certificates into the repo and store API keys or bundle identifiers in your local Xcode configuration only.
