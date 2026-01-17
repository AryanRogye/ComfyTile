//
//  PermissionService.swift
//  TilingWIndowManager_Test
//
//  Created by Aryan Rogye on 10/5/25.
//

import ApplicationServices
import AppKit


@Observable
class PermissionService {
    var isAccessibilityEnabled: Bool = false
    
    var permissionService: PermissionProviding = PermissionFetcherService()

    private var pollTimer: Timer?
    private var didBecomeActiveObserver: NSObjectProtocol?
    
    init() {
        self.isAccessibilityEnabled = permissionService.getAccessibilityPermissions()
        observeAppActivation()
        if !isAccessibilityEnabled {
            self.requestPermission()
        }
    }

    deinit {
        pollTimer?.invalidate()
        if let didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(didBecomeActiveObserver)
        }
    }
    
    public func resetAccessibility() throws {
        let process = Process()
        /// tccutil reset Accessibility com.aryanrogye.ComfyTile
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        
        process.arguments = [
            "reset",
            "Accessibility",
            "com.aryanrogye.ComfyTile"
        ]

        try process.run()
    }
    
    public func requestPermission() {
        let status = permissionService.requestAccessibilityPermission()
        permissionService.openPermissionSettings()
        self.isAccessibilityEnabled = status
        startPollingAccessibility()
    }
    public func openPermissionSettings() {
        permissionService.openPermissionSettings()
    }

    private func startPollingAccessibility() {
        pollTimer?.invalidate()

        var tries = 0
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            tries += 1
            let status = self.permissionService.getAccessibilityPermissions()
            if status != self.isAccessibilityEnabled {
                self.isAccessibilityEnabled = status
            }

            if status || tries > 30 {
                timer.invalidate()
                self.pollTimer = nil
            }
        }
    }

    private func observeAppActivation() {
        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let status = self.permissionService.getAccessibilityPermissions()
            if status != self.isAccessibilityEnabled {
                self.isAccessibilityEnabled = status
            }
        }
    }
}

protocol PermissionProviding {
    func getAccessibilityPermissions() -> Bool
    func openPermissionSettings()
    func requestAccessibilityPermission() -> Bool
}

class PermissionFetcherService: PermissionProviding {
    
    func getAccessibilityPermissions() -> Bool {
        AXIsProcessTrusted()
    }
    
    func openPermissionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Request Accessibility Permissions
    func requestAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let status = AXIsProcessTrustedWithOptions(options)
        
        if !status {
            print("Accessibility permission denied.")
        } else {
            print("Accessibility permission granted.")
        }

        return status
    }
}
