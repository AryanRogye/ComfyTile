//
//  SettingsView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/7/25.
//

import SwiftUI
import ComfyLogger
import Sparkle

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case appereance = "Appeareance"
    case log = "Log"
}

struct SettingsView: View {
    
    @Environment(DefaultsManager.self) var defaultsManager
    @Environment(SettingsViewModel.self) var settingsVM
    
    private var borderColor: Color {
        Color.secondary
    }
    private var strokeColor: Color {
        borderColor.opacity(0.2)
    }
    
    var body: some View {
        @Bindable var settingsVM = settingsVM
        NavigationStack {
            VStack(spacing: 0) {
                if !defaultsManager.useWindowInsteadOfMenuBar {
                    if defaultsManager.comfyTileTabPlacement == .bottom {
                        SettingsTopBar() {
                            settingsVM.isSidebarOpen.toggle()
                        }
                        .transition(.move(edge: .bottom).combined(with: .slide))
                    }
                }
                
                HStack(spacing: 0) {
                    if settingsVM.isSidebarOpen {
                        SettingsSidebar(selected: $settingsVM.selectedTab)
                            .transition(.move(edge: .leading))
                    }
                    
                    VStack{strokeColor}.frame(maxWidth: 0.5)
                    
                    VStack {
                        SettingsContent()
                    }
                }
                .animation(.snappy, value: settingsVM.isSidebarOpen)
                
                
                if !defaultsManager.useWindowInsteadOfMenuBar {
                    if defaultsManager.comfyTileTabPlacement == .top {
                        SettingsTopBar() {
                            settingsVM.isSidebarOpen.toggle()
                        }
                        .transition(.move(edge: .bottom).combined(with: .slide))
                    }
                }
            }
            .if(defaultsManager.useWindowInsteadOfMenuBar) {
                $0.customToolbar {
                    settingsVM.isSidebarOpen.toggle()
                }
            }
//            .toolbar {
//                if defaultsManager.useWindowInsteadOfMenuBar {
//                    ToolbarItem(placement: .navigation) {
//                        Button {
//                            settingsVM.isSidebarOpen.toggle()
//                        } label: {
//                            Image(systemName: "sidebar.left")
//                                .padding()
//                                .contentShape(Rectangle())
//                        }.buttonStyle(.plain)
//                    }
//                }
//            }
        }
        .animation(.snappy(duration: 0.15, extraBounce: 0.1), value: defaultsManager.comfyTileTabPlacement)
    }
}

extension View {
    public func customToolbar(onToggleOpen: @escaping () -> Void) -> some View {
        background(ToolbarWindowAccessor(onToggleOpen: onToggleOpen))
    }
}

fileprivate struct ToolbarWindowAccessor: NSViewRepresentable {
    
    let onToggleOpen: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let v = ToolbarWindowAccessorView(onToggleOpen: onToggleOpen)
        return v
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension NSToolbarItem.Identifier {
    static let customSwiftUIItem = NSToolbarItem.Identifier("com.aryanrogye.ComfyTile")
}

fileprivate struct ToolbarView: View {
    let onToggleOpen: () -> Void
    
    var body: some View {
        Button {
            onToggleOpen()
        } label: {
            Image(systemName: "sidebar.left")
                .padding(.horizontal, 6)
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

class ToolbarDelegate: NSObject, NSToolbarDelegate  {
    
    let onToggleOpen: () -> Void
    
    init(onToggleOpen: @escaping () -> Void) {
        self.onToggleOpen = onToggleOpen
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.customSwiftUIItem, .flexibleSpace, .space]
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.customSwiftUIItem]
    }
    
    // Inject the SwiftUI view into the AppKit Toolbar Item
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        if itemIdentifier == .customSwiftUIItem {
            let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            
            let hostingView = NSHostingView(
                rootView: ToolbarView(onToggleOpen: onToggleOpen)
            )
            
            hostingView.frame = NSRect(
                x: 0,
                y: 0,
                width: 64,
                height: 32
            )
            
            // 3. Assign the view to the toolbar item
            toolbarItem.view = hostingView
            toolbarItem.label = "Custom Actions"
            
            return toolbarItem
        }
        
        return nil
    }
}

class ToolbarWindowAccessorView: NSView {
    
    let toolbar = NSToolbar()
    let delegate : ToolbarDelegate
    let onToggleOpen: () -> Void
                                     
    init(onToggleOpen: @escaping () -> Void) {
        self.onToggleOpen = onToggleOpen
        self.delegate = ToolbarDelegate(onToggleOpen: onToggleOpen)
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not Yet Implemented")
    }
    
    override func viewDidMoveToWindow() {
        guard let window else { return }
        guard window.toolbar == nil else { return }
        
        toolbar.delegate = delegate
        toolbar.displayMode = .iconOnly
        
        window.toolbar = toolbar
    }
}

#Preview {
    SettingsView()
}
