//
//  WindowViewer.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 11/3/25.
//

import SwiftUI
import LocalShortcuts


struct LocalShortcutListener: NSViewRepresentable {
    func makeNSView(context: Context) -> ListenerView {
        let v = ListenerView()
        return v
    }
    
    func updateNSView(_ nsView: ListenerView, context: Context) {
        
    }
    
    class ListenerView: NSView {
        
        override func viewDidMoveToWindow() {
            print("View Init")
        }
        
        override func keyUp(with event: NSEvent) {
            let shortcut : LocalShortcuts.Shortcut = LocalShortcuts.Shortcut.getShortcut(event: event)
            
            print("Key Up: \(shortcut.modifiers()), \(shortcut.keyValues())")
        }
        override func keyDown(with event: NSEvent) {
            
            let shortcut : LocalShortcuts.Shortcut = LocalShortcuts.Shortcut.getShortcut(event: event)
            
            print("Key Down: \(shortcut.modifiers()), \(shortcut.keyValues())")
        }
    }
}

struct WindowViewer: View {
    
    @Bindable var windowViewerVM : WindowViewerViewModel
    @Bindable var fetchedWindowManager : FetchedWindowManager
    
    var body: some View {
        VStack {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                ForEach(fetchedWindowManager.fetchedWindows, id: \.self) { window in
                    Button(action: {
                        window.focusWindow()
                    }) {
                        VStack {
                            if let sc = window.screenshot {
                                Image(decorative: sc, scale: 1.0)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 150)
                            }
                            Text(window.windowTitle)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
