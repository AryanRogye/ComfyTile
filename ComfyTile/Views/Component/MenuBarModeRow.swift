//
//  MenuBarModeRow.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/10/26.
//

import SwiftUI


/**
 * MenuBarMode's Need same type of style, most of the time
 * we wrap that behavior in a custom `MenuBarModeRow`
 * this will let us apply MenuBarModeRowBackground and make
 * consistent behavior
 */
struct MenuBarModeRow<Content: View>: View {
    
    @Binding var allowClick: Bool
    let onClick: () -> Void
    var roundTop: Bool = false
    @Binding var hoveringOverSomethingElse: Bool
    
    @ViewBuilder var icon: () -> Content
    @ViewBuilder var name: () -> Content
    @ViewBuilder var shortcutButton: () -> Content
    
    var body: some View {
        HStack(alignment: .center) {
            icon()
            name()
            Spacer()
            shortcutButton()
        }
        .modifier(
            MenuBarModeRowBackground(
                roundTop: roundTop,
                height: 35,
                hoveringOverSomethingElse: $hoveringOverSomethingElse,
                allowClick: $allowClick
            )
        )
        .onTapGesture {
            if allowClick && !hoveringOverSomethingElse {
                onClick()
            }
        }
    }
}

struct MenuBarModeRowBackground: ViewModifier {
    
    let roundTop: Bool
    let height: CGFloat
    @Binding var hoveringOverSomethingElse: Bool
    @Binding var allowClick: Bool
    @State private var isHovering: Bool = false
    @State private var lastHover: Bool = false
    
    var backgroundColor: Color {
        isHovering && allowClick
        ? .secondary.opacity(0.2)
        : .clear
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                if roundTop {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 12,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 12
                    )
                    .fill(backgroundColor)
                } else {
                    backgroundColor
                }
            }
            .contentShape(Rectangle())
            .onHover { isHovering in
                /// If hovering over something else cancel this hover
                if hoveringOverSomethingElse {
                    self.isHovering = false
                    self.lastHover = isHovering
                    return
                }
                self.isHovering = isHovering
                self.lastHover  = isHovering
            }
            .onChange(of: hoveringOverSomethingElse) { _, newValue in
                /// If hovering over something else cancel this hover
                if newValue {
                    self.isHovering = false
                } else {
                    self.isHovering = self.lastHover
                }
            }
            .animation(.snappy, value: isHovering)
    }
}
