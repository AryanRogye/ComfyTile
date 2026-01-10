//
//  LayoutModeView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/10/26.
//

import SwiftUI

struct LayoutModeView: View {
    var body: some View {
        ScrollView {
            ForEach(LayoutMode.allCases, id: \.self) { layout in
                Text(layout.rawValue)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
