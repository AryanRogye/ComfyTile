//
//  FetchedWindowManager.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 11/2/25.
//

import ScreenCaptureKit

@Observable @MainActor
final class FetchedWindowManager {
    /// Seed Fetched Windows At Start
    var fetchedWindows : [FetchedWindow] = []
    
    init() {
        Task {
            await loadWindows()
        }
    }
    
    public func loadWindows() async {
        guard let fw = await getUserWindows() else { return }
        
        // fast lookup of the newest snapshot by windowID
        let newByID = Dictionary(uniqueKeysWithValues: fw.map { ($0.windowID, $0) })
        
        var merged: [FetchedWindow] = []
        merged.reserveCapacity(fw.count)
        
        // 1) keep current (rearranged) order, but replace each element with the fresh snapshot
        for old in fetchedWindows {
            if let updated = newByID[old.windowID] {
                merged.append(updated)
            }
        }
        
        // 2) append brand new windows that weren't already in your list
        let existingIDs = Set(merged.map { $0.windowID })
        for w in fw where !existingIDs.contains(w.windowID) {
            merged.append(w)
        }
        
        fetchedWindows = merged
    }
    
    /// Gets ALL User Windows
    public func getUserWindows() async -> [FetchedWindow]? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
            let allOnScreenWindows = content.windows
            var focusedWindows: [FetchedWindow] = []
            
            /// Loop Through all screens for windows
            for window in allOnScreenWindows {
                guard let app = window.owningApplication,
                      window.windowLayer == 0,
                      window.frame.size.width > 100
                else {
                    // Skip junk like "Cursor", "Menubar", etc.
                    continue
                }
                
                /// Get Window Information
                guard let windowInfo = CGWindowListCopyWindowInfo([.optionIncludingWindow], window.windowID) as? [[String: Any]],
                      let firstWindow = windowInfo.first,
                      let windowTitle = firstWindow["kCGWindowName"] as? String,
                      let pid = firstWindow["kCGWindowOwnerPID"] as? pid_t,
                      let boundsDict = firstWindow["kCGWindowBounds"] as? [String: CGFloat],
                      let x = boundsDict["X"],
                      let y = boundsDict["Y"],
                      let width = boundsDict["Width"],
                      let height = boundsDict["Height"]
                else { continue }
                
                /// Calulate Bounds
                let bounds = CGRect(x: x, y: y, width: width, height: height)
                
                /// Get AXElement, Doesnt matter if nil
                let axElement = AXUtils.findMatchingAXWindow(
                    pid: pid,
                    targetCGSFrame: bounds
                )
                
                /// Get Screenshot
                var screenshot: CGImage? = nil
                do {
                    screenshot = try await ScreenshotHelper.capture(windowID: window.windowID)
                } catch {
                    print("Coudlnt get screenshot: \(error)")
                }
                
                let spaces = spacesForWindow(window.windowID)
                let isInSpace = !spaces.isEmpty
                
                
                let windowElement = WindowElement(element: axElement)
                print("SCFrameworkID: \(window.windowID), ELEMENT_ID: \(windowElement.cgWindowID, default: "nil")")
                
                /// Add
                focusedWindows.append(FetchedWindow(
                    windowID: window.windowID,
                    windowTitle: windowTitle,
                    pid: pid,
                    element: windowElement,
                    bundleIdentifier: app.bundleIdentifier,
                    screenshot: screenshot,
                    isInSpace: isInSpace
                ))
            }
            return focusedWindows
        } catch {
            return nil
        }
    }
    
    
    private func spacesForWindow(_ windowID: CGWindowID) -> [Int] {
        let cid = CGSMainConnectionID()
        let ids: CFArray = [NSNumber(value: Int(windowID))] as CFArray
        
        guard let unmanaged = CGSCopySpacesForWindows(cid, kCGSAllSpacesMask, ids) else {
            return []
        }
        
        // Usually retained for “Copy” functions
        let cfArray = unmanaged.takeRetainedValue()
        
        // Bridge to Swift
        let nums = cfArray as NSArray as? [NSNumber] ?? []
        return nums.map { $0.intValue }
    }
}
