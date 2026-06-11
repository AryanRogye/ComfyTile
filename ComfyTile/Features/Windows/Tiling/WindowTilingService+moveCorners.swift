//
//  WindowTilingService+moveCorners.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/11/26.
//

import Cocoa

private enum WindowCorner {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

extension WindowTilingService {
    public func moveTopLeft(withAnimation: Bool) {
        move(to: .topLeft, withAnimation: withAnimation)
    }

    public func moveTopRight(withAnimation: Bool) {
        move(to: .topRight, withAnimation: withAnimation)
    }

    public func moveBottomLeft(withAnimation: Bool) {
        move(to: .bottomLeft, withAnimation: withAnimation)
    }

    public func moveBottomRight(withAnimation: Bool) {
        move(to: .bottomRight, withAnimation: withAnimation)
    }

    public func getTopLeftDimensions() -> CGRect? {
        cornerRect(for: .topLeft)
    }

    public func getTopRightDimensions() -> CGRect? {
        cornerRect(for: .topRight)
    }

    public func getBottomLeftDimensions() -> CGRect? {
        cornerRect(for: .bottomLeft)
    }

    public func getBottomRightDimensions() -> CGRect? {
        cornerRect(for: .bottomRight)
    }

    private func move(to corner: WindowCorner, withAnimation: Bool) {
        let (focusedWindow, screen) = getFocusedAndScreen()
        
        guard let focusedWindow, let screen, let rect =
                cornerRect(for: corner, on: screen) else {
            return
        }

        let position = rect.axPosition(on: screen)
        let resize = {
            focusedWindow.element.setSize(
                width: rect.width,
                height: rect.height
            )
        }

        resetSmartTiling()

        if withAnimation {
            animator.animate(focusedWindow: focusedWindow, to: position, duration: 0.13) {
                resize()
            }
        } else {
            focusedWindow.element.setPosition(x: position.x, y: position.y)
            resize()
        }
    }

    private func cornerRect(for corner: WindowCorner) -> CGRect? {
        guard let screen = WindowCore.screenUnderMouse() else { return nil }
        return cornerRect(for: corner, on: screen)
    }

    private func cornerRect(for corner: WindowCorner, on screen: NSScreen) -> CGRect? {
        let frame = screen.visibleFrame
        let width = frame.width / 2
        let height = frame.height / 2

        switch corner {
        case .topLeft:
            return CGRect(x: frame.minX, y: frame.minY + height, width: width, height: height)
        case .topRight:
            return CGRect(x: frame.minX + width, y: frame.minY + height, width: width, height: height)
        case .bottomLeft:
            return CGRect(x: frame.minX, y: frame.minY, width: width, height: height)
        case .bottomRight:
            return CGRect(x: frame.minX + width, y: frame.minY, width: width, height: height)
        }
    }
}
