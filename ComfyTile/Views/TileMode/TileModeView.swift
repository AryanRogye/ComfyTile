//
//  TileModeView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/10/26.
//

import SwiftUI

struct TileModeView: View {
    var body: some View {
        ScrollView {
            ForEach(TilingMode.allCases, id: \.self) { tile in
                Text(tile.rawValue)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
