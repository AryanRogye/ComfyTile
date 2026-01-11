//
//  FocusedWindow.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/6/26.
//

import Cocoa


class FocusedWindow {
    /// More stronger element
    var element: WindowElement
    var screen: NSScreen
    let pid: pid_t
    let bundleIdentifier: String?
    
    init(
        element: WindowElement,
        screen: NSScreen,
        bundleIdentifier: String?,
        pid: pid_t
    ) {
        self.element = element
        self.screen = screen
        self.bundleIdentifier = bundleIdentifier
        self.pid = pid
    }
}
