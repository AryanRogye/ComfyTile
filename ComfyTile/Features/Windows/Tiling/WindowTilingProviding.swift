//
//  WindowTilingProviding.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

import AppKit

protocol WindowTilingProviding {
    
    func nudgeTopUp(with step: Int)
    func nudgeTopDown(with step: Int)
    func nudgeBottomDown(with step: Int)
    func nudgeBottomUp(with step: Int)
    
    func getFullScreenDimensions() -> CGRect?
    func getCenterDimensions() -> CGRect?
    func getRightDimensions() -> CGRect?
    func getLeftDimensions() -> CGRect?
    
    func fullScreen(withAnimation: Bool)
    func center(withAnimation: Bool)
    func moveRight(withAnimation: Bool)
    func moveLeft(withAnimation: Bool)
}
