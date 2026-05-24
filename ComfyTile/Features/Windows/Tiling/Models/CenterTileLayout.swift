//
//  CenterTileLayout.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/24/26.
//


import Foundation

enum CenterTileLayout {
    case center
    case centerExpanded

    public mutating func nextLayout() {
        switch self {
        case .center:         self = .centerExpanded
        case .centerExpanded: self = .center
        }
    }
}
