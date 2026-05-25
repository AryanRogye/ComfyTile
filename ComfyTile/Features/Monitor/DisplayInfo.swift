//
//  DisplayInfo.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/25/26.
//

import CoreGraphics
import SwiftData

@Model
final class DisplayInfo {

    var name: String
    /// just UInt32
    var screenID: CGDirectDisplayID
    var padding: Double?

    // display values
    var width: CGFloat
    var height: CGFloat

    init(
        name: String,
        screenID: CGDirectDisplayID,
        padding: Double? = nil,
        width: CGFloat,
        height: CGFloat
    ) {
        self.name = name
        self.screenID = screenID
        self.padding = padding
        self.width = width
        self.height = height
    }
}
