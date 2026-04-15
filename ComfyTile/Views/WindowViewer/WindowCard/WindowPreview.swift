//
//  WindowPreview.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 4/15/26.
//

import SwiftUI

struct WindowPreview: View {
    let appScreenshot: CGImage?
    
    var body: some View {
        if let appScreenshot {
            Image(decorative: appScreenshot, scale: 1.0)
                .resizable()
        } else {
            Rectangle()
                .fill(Color.secondary)
        }
    }
}
