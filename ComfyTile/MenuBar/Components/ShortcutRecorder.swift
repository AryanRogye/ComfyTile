//
//  ShortcutRecorder.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 10/5/25.
//

import SwiftUI
import KeyboardShortcuts

struct ShortcutRecorder: View {
    
    var label : String
    var type  : KeyboardShortcuts.Name
    var tileShape : TileShape? = nil
    
    var body: some View {
        HStack(alignment: .center) {
            if let shape = tileShape {
                shape.view(color: .accentColor)
                    .frame(width: 13, height: 13)
            }
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            KeyboardShortcuts.Recorder("", name: type)
        }
        .padding(.horizontal)
    }
}
