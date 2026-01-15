//
//  WindowLayoutProviding.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/15/26.
//

protocol WindowLayoutProviding {
    func primaryLayout(window: [ComfyWindow]) async
    func primaryLeftStackedHorizontally(window: [ComfyWindow]) async
    func primaryRightStackedHorizontally(window: [ComfyWindow]) async
}
