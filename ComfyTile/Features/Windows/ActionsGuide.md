# Actions Guide

This guide explains how to add new window actions.


## Action Types

There are two main types of actions:

### Tiling Actions

Tiling actions directly move or resize a window.

There are two variants:

- **Tile**
    - Full tiling actions with preview + animation support.
    - Example: Left Half, Right Half, Top Half
    - New implementations go in a new `WindowTilingService+<name>.swift` extension file:
        ```bash
        ComfyTile/Features/Windows/Tiling
        ├── Models
        │   ├── CenterTileLayout.swift
        │   └── HorizontalTileLayout.swift
        ├── WindowAnimator.swift
        ├── WindowTilingProviding.swift
        ├── WindowTilingService.swift
        ├── WindowTilingService+center.swift
        ├── WindowTilingService+fullScreen.swift
        ├── WindowTilingService+moveBottomHalf.swift
        ├── WindowTilingService+moveLeft.swift
        ├── WindowTilingService+moveRight.swift
        └── WindowTilingService+moveTopHalf.swift
        ```

- **Nudge**
    - Simple window adjustments without preview behavior.
    - Example: nudgeBottomDown, nudgeBottomUp, etc...
    - Nudging will go inside [WindowTilingService](./Tiling/WindowTilingService.swift)

#### Creating New Tiling Actions

1. Start with [HotKeyCoordinator](../../Coordinators/HotKeyCoordinator.swift)
    - Add New Names to the `KeyboardShortcuts.Name`
    - Add closure parameters to `HotKeyCoordinator.start(...)`
    - Create `onKeyDown` and `onKeyUp` functions that call these closures
    - Animated tiles use `onKeyDown` for the `Pressed()` preview function and `onKeyUp` for the final action
    - Nudges only need `onKeyDown`
2. Create Functions in [WindowTilingProviding](./Tiling/WindowTilingProviding.swift)
    - Tiling needs dimension functions for animations
3. Implement Functions in WindowTilingService+______.swift
4. Add new case to [TilingMode](./Models/TilingMode.swift)
    - Add the new case to the `hotkey` and `tileShape` switches
5. make a new shape in [TileShapeView](../../Views/MenuBar/Components/TileShapeView.swift) because [TilingMode](./Models/TilingMode.swift) requires a `var tileShape: TileShape` for each property
6. fill out `action(for tile: TilingMode)` in [WindowSpatialEngine](./WindowSpatialEngine.swift)
    - This would require plugging in the newly created functions in [WindowTilingProviding](./Tiling/WindowTilingProviding.swift)
7. Wire up closures in [HotKeyCoordinator](../../Coordinators/HotKeyCoordinator.swift) to [AppCoordinator](../../App/AppCoordinator.swift)
    - Most likely this will call [WindowSpatialEngine](./WindowSpatialEngine.swift)
    - If Nudging, Functions are deadsimple, create them how they sound calling the appropriate [WindowTilingProviding](./Tiling/WindowTilingProviding.swift) function
    - For Example:
        ```swift
        public func nudgeBottomDown() {
            /// WindowTilingService Function Here
        }
        ```
    - If Tiling, 2 Functions will be created, verb function and verb function + Pressed()
    - For Example: 
        ```swift
        public func tileBottomHalf() {
            tileWithAnimation {
                /// WindowTilingService Function Here
            }
        }
        public func tileBottomHalfPressed() {
            if !defaultsManager.showTilingAnimations {
                /// WindowTilingService Function Here
                return
            }
            tileDownWithAnimation {
                /// WindowTilingService Function Here
            }
        }
        ```
---
### Layout Actions

Layouts apply a predefined window arrangement.

- One-shot actions
- No preview animations
- Execute immediately

#### Creating New Layout Actions

1. Start with [HotKeyCoordinator](../../Coordinators/HotKeyCoordinator.swift)
    - Add New Names to the `KeyboardShortcuts.Name`
    - Add closure parameters to `HotKeyCoordinator.start(...)`
    - Create `onKeyDown` functions, this would only need onKeyDown, not `onKeyUp`
2. Create Functions in [WindowLayoutProviding](./Layout/WindowLayoutProviding.swift)
3. Implement Functions in [WindowLayoutService](./Layout/WindowLayoutService.swift)
4. add new case to [LayoutMode](./Models/LayoutMode.swift)
    - Add the new case to the `hotkey` switch
5. fill out `action(for layout: LayoutMode)` in [WindowSpatialEngine](./WindowSpatialEngine.swift)
    - This would require plugging in the newly created functions in [WindowLayoutProviding](./Layout/WindowLayoutProviding.swift)
6. Wire up closures in [HotKeyCoordinator](../../Coordinators/HotKeyCoordinator.swift) to [AppCoordinator](../../App/AppCoordinator.swift)
    - Most likely this will call [WindowSpatialEngine](./WindowSpatialEngine.swift)
    - Layout functions are simple wrappers around [WindowLayoutProviding](./Layout/WindowLayoutProviding.swift) name them based on the action they perform
    ```swift
    public func primaryLeftStackedHorizontallyTile() {
        Task {
            /// WindowLayoutService Function
        }
    }
    ```
