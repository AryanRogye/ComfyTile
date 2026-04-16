//
//  WindowCard.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 4/15/26.
//

import SwiftUI

struct WindowCard: View {
    
    @Environment(\.colorScheme) private var scheme
    let appName: String
    let windowTitle: String
    let appIcon: NSImage?
    let appScreenshot: CGImage?
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    var onClose: () -> Void
    var onMinimize: () -> Void
    var onMaximize: () -> Void
    let selected: Bool
    let selectionNamespace: Namespace.ID
    
    /// 1/5 goes to the top
    var topHeight: CGFloat {
        cardHeight * 0.15
    }
    
    /// 4/5 goes to the bottom
    var bottomHeight: CGFloat {
        cardHeight * 0.85
    }
    
    var paddingAround: CGFloat {
        6
    }
    
    var spacingBetween: CGFloat {
        2
    }
    
    var shape : RoundedRectangle {
        RoundedRectangle(cornerRadius: 22)
    }
    
    var backgroundColor: AnyShapeStyle {
        (selected
         /// Selected Background
         ? AnyShapeStyle(Color.accentColor.opacity(0.2))
         /// Not Selected Background
         : (scheme == .dark
            /// Dark Background
            ? AnyShapeStyle(.black.opacity(0.2))
            /// Light Background
            : AnyShapeStyle(.regularMaterial)
           )
        )
    }
    
    var cardStrokeColor: Color {
        /// If selected then show accent color
        (selected ? Color.accentColor
         : ( scheme == .dark
             /// if dark mode show black border
             ? Color.black.opacity(0.2)
             /// if light mode show dark border but lighter
             : Color.black.opacity(0.1)
           )
        )
    }
    
    var trafficLightBackground: AnyShapeStyle {
        selected
        ? AnyShapeStyle(Color.accentColor.opacity(0.1))
        : AnyShapeStyle(.regularMaterial.opacity(0.2))
    }
    
    var body: some View {
        VStack(spacing: spacingBetween) {
            /// Top Area
            HStack(spacing: 0) {
                WindowTrafficLights(
                    onClose: onClose,
                    onMinimize: onMinimize,
                    onMaximize: onMaximize,
                    selected: selected,
                    shape: shape,
                    trafficLightBackground: trafficLightBackground
                )
                Spacer()
                WindowTitleView(
                    appName: appName,
                    windowTitle: windowTitle,
                    appIcon: appIcon,
                    topHeight: topHeight
                )
            }
            .padding(.horizontal, paddingAround)
            .frame(
                height: topHeight
            )
            
            /// Bottom Area
            WindowPreview(appScreenshot: appScreenshot)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(shape)
        }
        .padding(paddingAround)
        /// This is height so we can force it
        .frame(height: cardHeight, alignment: .top)
        .background {
            shape
                .fill(backgroundColor)
                .overlay {
                    if selected {
                        shape
                            .stroke(.white.opacity(0.9), lineWidth: 1)
                            .blur(radius: 20)
                            .matchedGeometryEffect(id: "selected-glow", in: selectionNamespace)
                    }
                }
                .overlay {
                    if selected {
                        shape
                            .stroke(Color.accentColor, lineWidth: 1.5)
                            .matchedGeometryEffect(id: "selected-border", in: selectionNamespace)
                    } else {
                        shape
                            .stroke(cardStrokeColor, lineWidth: 1.5)
                    }
                }
        }
        .animation(.snappy, value: selected)
    }
}
