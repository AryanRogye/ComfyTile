//
//  WindowTilingProviding.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

import AppKit

public protocol WindowTilingProviding {

    func setPaddingForScreen(_ padding: @escaping (NSScreen) -> CGFloat?)

    func nudgeTopUp(with step: Int)
    func nudgeTopDown(with step: Int)
    func nudgeBottomDown(with step: Int)
    func nudgeBottomUp(with step: Int)
    
    func getFullScreenDimensions() -> CGRect?
    func getCenterDimensions(padding: Double, isLayoutCycling: Bool, isUsingAdvancedPadding: Bool) -> CGRect?
    func getRightDimensions(isLayoutCycling: Bool, enableSmartTiling: Bool) -> CGRect?
    func getLeftDimensions(isLayoutCycling: Bool, enableSmartTiling: Bool) -> CGRect?
    func getTopHalfDimensions() -> CGRect?
    func getBottomHalfDimensions() -> CGRect?
    func getTopLeftDimensions() -> CGRect?
    func getTopRightDimensions() -> CGRect?
    func getBottomLeftDimensions() -> CGRect?
    func getBottomRightDimensions() -> CGRect?
    
    func fullScreen(withAnimation: Bool)
    func center(withAnimation: Bool, padding: Double, isLayoutCycling: Bool, isUsingAdvancedPadding: Bool)
    func moveRight(withAnimation: Bool, isLayoutCycling: Bool, enableSmartTiling: Bool)
    func moveLeft(withAnimation: Bool, isLayoutCycling: Bool, enableSmartTiling: Bool)
    func moveTopHalf(withAnimation: Bool)
    func moveBottomHalf(withAnimation: Bool)
    func moveTopLeft(withAnimation: Bool)
    func moveTopRight(withAnimation: Bool)
    func moveBottomLeft(withAnimation: Bool)
    func moveBottomRight(withAnimation: Bool)
}
