//
//  PermissionView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/5/26.
//

import SwiftUI

struct PermissionView: View {
    
    @Bindable var vm : ComfyTileMenuBarViewModel
    @State private var clickedPermissions: Bool = false

    var body: some View {
        VStack {
            Text("👀 ComfyTile can’t see your windows yet.\nTurn on Accessibility so it can actually do its job.")

            Spacer()
            Button(action: {
                clickedPermissions = true
                vm.permissionService.requestPermission()
                vm.closePanel()
            }) {
                if clickedPermissions {
                    Text("😐 macOS still pretending we don’t exist?")
                } else {
                    Text("Request Accessibility")
                }
            }
            if clickedPermissions {
                Text("Sometimes macOS is just being stubborn. 😅")
                Button(action: {
                    try? vm.permissionService.resetAccessibility()
                }) {
                    Text("Reset Accessibility For ComfyTile")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
