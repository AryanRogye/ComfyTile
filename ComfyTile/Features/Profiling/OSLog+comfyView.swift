//
//  OSLog+comfyView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/25/26.
//

import os.signpost
import Foundation

extension OSLog {
    static let comfyView = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "com.aryanrogye.ComfyTile",
        category: .pointsOfInterest
    )
}
