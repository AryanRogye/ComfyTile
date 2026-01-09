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
    
    init(element: WindowElement, screen: NSScreen) {
        self.element = element
        self.screen = screen
    }
}
