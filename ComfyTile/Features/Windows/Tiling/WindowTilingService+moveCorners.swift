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
    func moveTopLeft(withAnimation: Bool) {
        move(to: .topLeft, withAnimation: withAnimation)
    }

    func moveTopRight(withAnimation: Bool) {
        move(to: .topRight, withAnimation: withAnimation)
    }

    func moveBottomLeft(withAnimation: Bool) {
        move(to: .bottomLeft, withAnimation: withAnimation)
    }

    func moveBottomRight(withAnimation: Bool) {
        move(to: .bottomRight, withAnimation: withAnimation)
    }

    func getTopLeftDimensions() -> CGRect? {
        cornerRect(for: .topLeft)
    }

    func getTopRightDimensions() -> CGRect? {
        cornerRect(for: .topRight)
    }

    func getBottomLeftDimensions() -> CGRect? {
        cornerRect(for: .bottomLeft)
    }

    func getBottomRightDimensions() -> CGRect? {
        cornerRect(for: .bottomRight)
    }

    private func move(to corner: WindowCorner, withAnimation: Bool) {
        guard let focusedWindow = windowCore.getFocusedWindow(),
              let screen = WindowCore.screenUnderMouse(),
              let rect = cornerRect(for: corner, on: screen) else { return }

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
