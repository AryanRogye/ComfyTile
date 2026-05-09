//
//  HorizontalTileLayout.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/9/26.
//

import Foundation

enum HorizontalTileLayout {
    case half
    case oneThird
    case twoThirds
    
    var widthMultiplier: CGFloat {
        switch self {
        case .half:      return 0.5
        case .oneThird:  return 1.0 / 3.0
        case .twoThirds: return 2.0 / 3.0
        }
    }
    
    public func complementary() -> Self {
        switch self {
        case .half:      return .half
        case .oneThird:  return .twoThirds
        case .twoThirds: return .oneThird
        }
    }
    
    public func last() -> Self {
        switch self {
        case .half:      return .twoThirds
        case .oneThird:  return .half
        case .twoThirds: return .oneThird
        }
    }
    
    public mutating func nextLayout() {
        switch self {
        case .half:      self = .oneThird
        case .oneThird:  self = .twoThirds
        case .twoThirds: self = .half
        }
    }
}
