//
//  WindowLayoutProviding.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

protocol WindowLayoutProviding {
    
    func nudgeTopUp(with step: Int)
    func nudgeTopDown(with step: Int)
    func nudgeBottomDown(with step: Int)
    func nudgeBottomUp(with step: Int)
    
    func fullScreen()
    func center()
    func moveRight()
    func moveLeft()
}
