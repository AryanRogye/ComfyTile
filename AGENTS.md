# Repository Guidelines

## Project Structure & Module Organization
Source code lives in `ComfyTile/` and is organized by feature flow.
- `ComfyTile/App/` contains app entry and startup coordination (`ComfyTileApp`, `AppDelegate`, `AppCoordinator`).
- `ComfyTile/Coordinators/` handles cross-feature orchestration (menu bar, hotkeys, overlays, window viewer).
- `ComfyTile/Features/Common/` contains shared platform concerns (`Input`, `Permission`, `Persistance`).
- `ComfyTile/Features/Windows/` contains core window management (models, layout, tiling, AX/CGS bridge utilities).
- `ComfyTile/Features/Updates/` contains Sparkle update flow (`Core`, `ViewModel`, `UI`).
- `ComfyTile/Views/` contains SwiftUI surfaces grouped by product area (`MenuBar`, `Settings`, `TileMode`, etc.).
- `ComfyTile/Extensions/` is for focused, stateless helpers.
- `ComfyLogger/` and `LocalShortcuts/` are local Swift packages used by the app.
- `updates/appcast.xml` stores the Sparkle appcast metadata for releases.

## Build, Test, and Development Commands
- `open ComfyTile.xcworkspace` opens the workspace with local packages wired in.
- `xcodebuild -project ComfyTile.xcodeproj -scheme ComfyTileApp -configuration Debug build` builds the app for local/CI debug validation.
- `xcodebuild -project ComfyTile.xcodeproj -scheme Release -configuration Release build` builds with release launch settings.
- `./scripts/gen_lsp.sh` regenerates `xcode-build-server` config for editor tooling.
- `./scripts/resetPerms.sh` resets TCC permissions for `com.aryanrogye.ComfyTile`.
- `./scripts/resetSparkle.sh` clears Sparkle defaults to retest update prompts.

## Coding Style & Naming Conventions
Use Swift 5 conventions: 4-space indentation, trailing commas in multiline literals, and whitespace around control-flow keywords. Use `PascalCase` for types and `camelCase` for properties/functions. Keep side effects and macOS API calls in `Features/*` or coordinators, not in SwiftUI views. Use `// MARK:` to separate logical sections, and place private helpers in `private`/`fileprivate` extensions when it improves readability.

## Testing Guidelines
There is currently no committed XCTest target. For new test coverage:
- Add a `ComfyTileTests/` group and XCTest target in the Xcode project.
- Name files `<Feature>Tests.swift` and test methods `test_<Scenario>_<Expectation>()`.
- Isolate AX/CGS and other macOS integrations behind protocols so unit tests stay deterministic.
- After adding tests, run `xcodebuild test -project ComfyTile.xcodeproj -scheme ComfyTileApp -destination 'platform=macOS'`.

## Commit & Pull Request Guidelines
Prefer concise, imperative commit subjects (for example: `fix tiling cover flicker`). Keep subject lines short and add detail in the body when behavior changes. For pull requests:
- Explain what changed and why in plain language.
- List impacted directories.
- Include validation steps you ran (`build`, `test`, manual scenarios).
- Attach screenshots or recordings for visible UI/menu bar changes.
- Link related issues or follow-ups.

## Security & Configuration Notes
`ComfyTile/ComfyTile.entitlements` and `ComfyTile/Features/Common/Permission/PermissionService.swift` control accessibility and automation capabilities. Re-verify permissions in System Settings after entitlement or AX behavior changes. Do not commit signing certificates, private keys, or machine-specific bundle/signing overrides.

## Adding Files
The Xcode project uses Groups (not folder references) for source organization.
- Add new files/folders as groups in `ComfyTile.xcodeproj`.
- Verify target membership for app sources, assets, and package code.
- Keep new files under the existing feature-based structure unless there is a strong reason to introduce a new top-level area.
