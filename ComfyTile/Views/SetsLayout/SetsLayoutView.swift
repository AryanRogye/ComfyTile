//
//  SetsLayoutView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 2/14/26.
//

import SwiftUI

struct SetsLayoutView: View {
    
    @Environment(ComfyTileMenuBarViewModel.self) var vm
    
    var body: some View {
        ScrollView {
            Button {
                
            } label: {
                Text("Start Watching Layout")
            }
            .padding(.top)
        }
    }
}
