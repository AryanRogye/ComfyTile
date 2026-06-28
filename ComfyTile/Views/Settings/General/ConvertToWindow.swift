//
//  ConvertToWindow.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/12/26.
//

import SwiftUI

struct ConvertToWindow: View {
    
    @Bindable var defaultsManager: DefaultsManager
    
    var body: some View {
        Toggle("Display as Window", isOn: $defaultsManager.useWindowInsteadOfMenuBar)
    }
}
