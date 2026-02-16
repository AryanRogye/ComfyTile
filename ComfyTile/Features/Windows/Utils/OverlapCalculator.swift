//
//  OverlapCalculator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/25/26.
//

import Cocoa

protocol Spatial { var bounds: CGRect { get } }
struct WindowKey: Spatial, Hashable {
    let windowID: CGWindowID?
    let pid: pid_t
    let bounds: CGRect
}


indirect enum RTreeEntry<K : Spatial, V> {
    case leaf(K, V)
    case branch(CGRect, RTreeNode<K, V>)
}

struct RTreeNode<K : Spatial, V> {
    var level: Int
    var entries: [RTreeEntry<K, V>]
}

struct RTree<K : Spatial, V> {
    var root: RTreeNode<K, V>
    
    init() {
        root = RTreeNode(level: 0, entries: [])
    }
    
    public func store(key :K, value :V) {
        
    }
}

final class OverlapCalculator {
    var storage : RTree<WindowKey, ComfyWindow> = .init()
    
    public func storeWindow(_ win: ComfyWindow) {
        let windowKey = WindowKey(
            windowID: win.windowID,
            pid: win.pid,
            bounds: win.element.frame
        )
        storage.store(key: windowKey, value: win)
    }
}
