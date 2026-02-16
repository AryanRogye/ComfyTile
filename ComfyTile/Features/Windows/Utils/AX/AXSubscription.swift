//
//  AXSubscription.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/22/26.
//

import ApplicationServices

/// Class listens for Changes done to the AXUIELement
public final class AXSubscription {
    
    let pid: pid_t
    var observer: AXObserver? = nil
    var watchingWindows: Set<CGWindowID> = []
    var onChange: ((pid_t, AXUIElement, CFString) -> Void)?
    
    init?(pid: pid_t) {
        self.pid = pid
        
        var obs: AXObserver?
        let err = AXObserverCreate(pid, Self.callback, &obs)
        guard err == .success, let observer = obs else {
            return nil
        }

        
        self.observer = observer
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(observer),
            .commonModes
        )
    }
    
    private var isWatchingApp = false
    private var isWatchingWindow = false
    
    func setHandlerIfNeeded(_ handler: @escaping (pid_t, AXUIElement, CFString) -> Void) {
        if onChange == nil { onChange = handler }
    }
    
    func watchApp() {
        guard !isWatchingApp else { return }
        let appEl = AXUIElementCreateApplication(pid)
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        
        add(appEl, kAXFocusedUIElementChangedNotification as CFString, ctx)
        add(appEl, kAXFocusedWindowChangedNotification as CFString, ctx)
        add(appEl, kAXApplicationActivatedNotification as CFString, ctx)
        add(appEl, kAXWindowMovedNotification as CFString, ctx)
        add(appEl, kAXWindowResizedNotification as CFString, ctx)
        isWatchingApp = true
    }
    
    func watchWindow(_ windowEl: AXUIElement, windowID: CGWindowID) {
        guard !isWatchingWindow else { return }
        // only dedupe the window-level stuff by windowID
        guard watchingWindows.insert(windowID).inserted else { return }
        
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        add(windowEl, kAXMovedNotification as CFString, ctx)
        add(windowEl, kAXResizedNotification as CFString, ctx)
        isWatchingWindow = true
    }
    
    private func add(_ el: AXUIElement, _ notif: CFString, _ ctx: UnsafeMutableRawPointer) {
        let err = AXObserverAddNotification(observer!, el, notif, ctx)
        if err != .success {
            print("❌ AXObserverAddNotification failed pid=\(pid) notif=\(notif) err=\(err)")
        }
    }
    
    private static let callback: AXObserverCallback = { observer, element, notification, refcon in
        
        guard let refcon else { return }
        
        let instance = Unmanaged<AXSubscription>
            .fromOpaque(refcon)
            .takeUnretainedValue()
        
        instance.handle(
            element: element,
            notification: notification
        )
    }
    
    private func handle(element: AXUIElement, notification: CFString) {
        onChange?(pid, element, notification)
    }
}
