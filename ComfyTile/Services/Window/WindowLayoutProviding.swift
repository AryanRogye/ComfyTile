//
//  WindowLayoutProviding.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

protocol WindowLayoutProviding {
    
    func nudgeTopUp()
    func nudgeTopDown()
    
    func nudgeBottomDown()
    func nudgeBottomUp()
    
    func fullScreen()
    func center()
    func moveRight()
    func moveLeft()
}
