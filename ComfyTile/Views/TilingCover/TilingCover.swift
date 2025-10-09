//
//  TilingCover.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/8/25.
//

import SwiftUI

struct TilingCover : View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .ignoresSafeArea()
            
            VStack {
                // content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
