//
//  WindowElement.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 1/15/26.
//

import Cocoa

public class WindowElement {
    public var element: AXUIElement?
    
    public init(element: AXUIElement?) {
        self.element = element
    }
    
    public var title: String? {
        get {
            return element?.getWrappedValue(.title)
        }
    }
    
    public var frame: CGRect {
        guard let position = position, let size = size else { return .null }
        return .init(origin: position, size: size)
    }
    
    @MainActor
    public var cgWindowID: CGWindowID? {
        get {
            return element?._cgWindowID()
        }
    }
    
    public var size: CGSize? {
        get {
            element?.getWrappedValue(.size)
        }
        set {
            guard let newValue = newValue else { return }
            element?.setValue(.size, newValue)
        }
    }
    
    public var position: CGPoint? {
        get {
            element?.getWrappedValue(.position)
        }
        set {
            guard let newValue = newValue else { return }
            element?.setValue(.position, newValue)
        }
    }
    
    public var windowFrame: CGRect? {
        guard let position else { return nil }
        guard let size else { return nil }
        return CGRect(origin: position, size: size)
    }
    
    public func setPosition(x: CGFloat, y: CGFloat) {
        position = CGPoint(x: x, y: y)
    }
    
    public func setSize(width: CGFloat, height: CGFloat) {
        size = CGSize(width: width, height: height)
    }
    
    public func setFrame(_ frame: CGRect, adjustSizeFirst: Bool = true) {
        if adjustSizeFirst {
            size = frame.size
        }
        position = frame.origin
        size = frame.size
    }
}
