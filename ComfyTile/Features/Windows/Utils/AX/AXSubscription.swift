//
//  AXSubscription.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/22/26.
//

import ApplicationServices

public final class AXSubscription {
    
    let pid: pid_t
    var observer: AXObserver? = nil
    
    var watchingWindows: Set<CGWindowID> = []
    
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
            .defaultMode
        )
    }
    
    func watch(_ element: AXUIElement, windowID: CGWindowID) {
        
        if watchingWindows.contains(windowID) { return }
        watchingWindows.insert(windowID)
        
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        
        AXObserverAddNotification(
            observer!,
            element,
            kAXMovedNotification as CFString,
            ctx
        )
        
        AXObserverAddNotification(
            observer!,
            element,
            kAXResizedNotification as CFString,
            ctx
        )
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
        print("PID:", pid, "Event:", notification)
    }
}
