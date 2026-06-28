//
//  TilingAnimationsView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/12/26.
//

import SwiftUI

struct TilingAnimationsView: View {
    
    @Bindable var defaultsManager: DefaultsManager
    
    var body: some View {
        Toggle("Tiling animations", isOn: $defaultsManager.showTilingAnimations)
            .toggleStyle(.switch)
    }
}
