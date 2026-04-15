//
//  WindowTitleView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 4/15/26.
//

import SwiftUI

struct WindowTitleView: View {
    
    let appName: String
    let windowTitle: String
    let appIcon: NSImage?
    let topHeight: CGFloat
    
    var body: some View {
        HStack(alignment: .center) {
            if let appIcon {
                Image(nsImage: appIcon)
                    .frame(width: 20, height: 20)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(appName)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                MarqueeText(
                    text: windowTitle,
                    font: .system(size: 10),
                    color: .secondary,
                    pointsPerSecond: 35,
                    startPause: 1.2,
                    endPause: 1.0,
                    resetDuration: 0.45,
                    trailingPadding: 20,
                    resetMode: .animated
                )
            }
        }
        .padding(.leading)
    }
}
