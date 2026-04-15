//
//  MarqueeText.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 4/15/26.
//

import SwiftUI

/**
 * Created with ChatGPT + Claude
 * this is so the title of the window can scroll
 */
struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    
    /// How fast the text moves in points per second
    let pointsPerSecond: CGFloat
    
    /// How long it waits before starting to scroll
    let startPause: Double
    
    /// How long it waits after reaching the end
    let endPause: Double
    
    /// How long the reset animation takes
    let resetDuration: Double
    
    /// Extra spacing so the text does not feel jammed at the edge
    let trailingPadding: CGFloat
    
    let resetMode: ResetMode
    
    enum ResetMode {
        case instant
        case animated
        case fade
    }
    
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var opacity: Double = 1
    
    @State private var animationTask: DispatchWorkItem?
    
    var body: some View {
        GeometryReader { geo in
            let container = geo.size.width
            
            ScrollView(.horizontal) {
                Text(text)
                    .font(font)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(
                        GeometryReader { textGeo in
                            Color.clear
                                .onAppear {
                                    textWidth = textGeo.size.width
                                    containerWidth = container
                                    restart()
                                }
                                .onChange(of: textGeo.size.width) { _, newValue in
                                    textWidth = newValue
                                    containerWidth = container
                                    restart()
                                }
                        }
                    )
                    .offset(x: offset)
                    .opacity(opacity)
            }
            .scrollDisabled(true)
            .clipped()
            .onChange(of: container) { _, newValue in
                containerWidth = newValue
                restart()
            }
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }
    
    private var needsScrolling: Bool {
        textWidth > containerWidth
    }
    
    private var travelDistance: CGFloat {
        max(0, textWidth - containerWidth + trailingPadding)
    }
    
    private var scrollDuration: Double {
        guard pointsPerSecond > 0 else { return 0 }
        return Double(travelDistance / pointsPerSecond)
    }
    
    private func restart() {
        animationTask?.cancel()
        offset = 0
        opacity = 1
        
        guard needsScrolling else { return }
        startScrollingCycle()
    }
    
    private func startScrollingCycle() {
        guard needsScrolling else { return }
        
        let task = DispatchWorkItem {
            withAnimation(.linear(duration: scrollDuration)) {
                offset = -travelDistance
            }
            
            scheduleNext(after: scrollDuration + endPause) {
                resetAndContinue()
            }
        }
        
        animationTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + startPause, execute: task)
    }
    
    private func resetAndContinue() {
        guard needsScrolling else { return }
        
        switch resetMode {
        case .instant:
            offset = 0
            startScrollingCycle()
            
        case .animated:
            withAnimation(.easeInOut(duration: resetDuration)) {
                offset = 0
            }
            
            scheduleNext(after: resetDuration) {
                startScrollingCycle()
            }
            
        case .fade:
            withAnimation(.easeOut(duration: resetDuration / 2)) {
                opacity = 0
            }
            
            scheduleNext(after: resetDuration / 2) {
                offset = 0
                
                withAnimation(.easeIn(duration: resetDuration / 2)) {
                    opacity = 1
                }
                
                scheduleNext(after: resetDuration / 2) {
                    startScrollingCycle()
                }
            }
        }
    }
    
    private func scheduleNext(after delay: Double, action: @escaping () -> Void) {
        let task = DispatchWorkItem(block: action)
        animationTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
    }
}
