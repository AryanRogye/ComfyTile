//
//  DisplayProfile.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/5/26.
//

import Foundation

struct DisplayProfile: Codable, Equatable {
    public var contrast: Double = 1.0
    public var brightness: Float = 1.0
    
    static let `default` = DisplayProfile()
}
