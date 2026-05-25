//
//  DisplayManager.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/24/26.
//


import Cocoa
import ScreenCaptureKit
import SwiftData

/// Runtime displays may exist without being persisted.
///
/// A DisplayInfo with `padding == nil` represents a connected display
/// that does not yet have a saved padding configuration.
///
/// Once padding is enabled, the DisplayInfo is inserted into SwiftData.
///
/// The idea is simple:
/// users may connect multiple monitors, but persistence only happens
/// when padding or another display configuration is applied.
@Observable
@MainActor
final class DisplayManager {

    var watcher: DisplayObserver?
    var ctx: ModelContext
    var screenSnapshots: [CGDirectDisplayID: NSImage] = [:]
    var displayInfos: [DisplayInfo] = []

    let defaultPadding: Double = 40


    init(ctx: ModelContext) {
        self.ctx = ctx
        syncDisplayInfos()
    }

    public func start() {
        updateScreenInformation()
        syncDisplayInfos()
        watcher = DisplayObserver(completionHandler: { _, _ in
            Task { @MainActor in
                self.updateScreenInformation()
                self.syncDisplayInfos()
            }
        })
    }

    public func stop() {
        watcher = nil
    }

    /// Syncs Display Info with SwiftData storage
    internal func syncDisplayInfos() {
        let descriptor = FetchDescriptor<DisplayInfo>()

        do {
            displayInfos = try ctx.fetch(descriptor)

            /// Populates screensnapshots this way the UI can show it
            for displayInfo in displayInfos {
                screenSnapshots[displayInfo.screenID] = getWallpaperImage(
                    size:  CGSize(
                        width: displayInfo.width,
                        height: displayInfo.height
                    ),
                    for: displayInfo.screenID
                )
            }
        } catch {
            displayInfos = []
        }
    }

    internal func addDisplayInfo(_ info: DisplayInfo) {
        ctx.insert(info)
        displayInfos.append(info)
        save()
    }

    internal func save() {
        do {
            try ctx.save()
        } catch {
            print("Failed to save DisplayInfo:", error)
        }
    }

    /// Ensures the screen has a DisplayInfo entry.
    ///
    /// If the screen is not already tracked, a new DisplayInfo
    /// is created, inserted into SwiftData, and appended to the
    /// local displayInfos cache.
    public func enablePadding(for screen: NSScreen) {
        guard let id = screen.displayID else { return }
        guard !displayInfos.contains(where: { $0.screenID == id }) else { return }
        let info = DisplayInfo(
            name: displayName(for: id),
            screenID: id,
            padding: defaultPadding,
            width: screen.frame.width,
            height: screen.frame.height
        )
        addDisplayInfo(info)
    }

    /// Deletion of screen in SwiftData
    ///
    /// if the screen doesnt exist we just return early
    public func disablePadding(for id: CGDirectDisplayID) {
        guard let info = displayInfos.first(where: { $0.screenID == id }) else { return }
        ctx.delete(info)
        displayInfos.removeAll(where: { $0.screenID == id })
        try? ctx.save()
    }

    /// Returns true or false if Screen exists in SwiftData
    public func isPaddingEnabled(for id: CGDirectDisplayID) -> Bool {
        displayInfos.contains(where: { $0.screenID == id })
    }

    /// Function updates padding for the screen
    ///
    /// if screenID is not in displayInfos we skip
    public func updatePadding(for id: CGDirectDisplayID, padding: Double) {

        if let info = displayInfos.first(where: { $0.screenID == id }) {
            info.padding = padding
            save()
            return
        }

        guard let id = screenSnapshots.keys.first(where: { $0 == id }) else {
            return
        }

        guard let screen = NSScreen.screens.first(where: { $0.displayID == id }) else { return }

        //        runtimeInfo.padding = padding
        let info = DisplayInfo(
            name: displayName(for: id),
            screenID: id,
            padding: padding,
            width: screen.frame.width,
            height: screen.frame.height
        )
        addDisplayInfo(info)
    }

    public func displayInfo(for id: CGDirectDisplayID) -> DisplayInfo? {
        return displayInfos.first(where: { $0.screenID == id })
    }

    /// Function to get the image of the id super fast
    ///
    /// we use screenSnapshots instead of displayInfos because
    /// screenSnapshots is always up to date
    public func snapshot(for id: CGDirectDisplayID) -> NSImage? {
        let info = screenSnapshots.keys.first(where: { $0 == id })
        guard let info else { return nil }
        return screenSnapshots[info] ?? nil
    }

    /// Function to get the name of the screen
    public func displayName(for displayID: CGDirectDisplayID) -> String {
        if let screen = NSScreen.screens.first(where: { $0.displayID == displayID }) {
            return screen.localizedName
        }
        return "Unknown Name"
    }

    private func updateScreenInformation() {
        let currentIDs = Set(NSScreen.screens.compactMap(\.displayID))

        for screen in NSScreen.screens {
            guard let id = screen.displayID else { continue }

            screenSnapshots[id] = getWallpaperImage(size: screen.frame.size, for: id)
        }

        /// check current snapshots for the monitor
        for info in Array(screenSnapshots.keys) {
            let isCurrentlyConnected = currentIDs.contains(info)
            if !isCurrentlyConnected {
                screenSnapshots.removeValue(forKey: info)
            }
        }
    }



    private func getWallpaperImage(size: CGSize, for displayID: CGDirectDisplayID) -> NSImage {

        func makePlaceholderImage(size: CGSize) -> NSImage {
            let image = NSImage(size: size)

            image.lockFocus()
            NSColor.lightGray.setFill()
            NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
            image.unlockFocus()

            return image
        }

        /// we will find displayID in NSScreens, if doesnt exist we will default to the main
        guard let screen = NSScreen.screens.first(where: { $0.displayID == displayID }) ?? NSScreen.main else { return makePlaceholderImage(size: size) }

        if let wallpaperURL = NSWorkspace.shared.desktopImageURL(for: screen),
           let image = NSImage(contentsOf: wallpaperURL)  {
            return image
        }

        return makePlaceholderImage(size: size)
    }
}
