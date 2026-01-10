//
//  MenuBarModeContainer.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/10/26.
//

import SwiftUI

/**
 * MenuBar Mode Content is almost identical including the
 * Container its held in
 */
struct MenuBarContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                content()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
