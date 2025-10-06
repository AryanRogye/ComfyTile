//
//  TileShapeView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/5/25.
//

import SwiftUI

enum TileShape {
    case center,
         full,
         left,
         right,
         nudgeTopUp,
         nudgeTopDown,
         nudgeBottomUp,
         nudgeBottomDown
    
    
    @ViewBuilder
    func view(color: Color) -> some View {
        switch self {
        case .left, .right:
            HorizontalTileSideView(side: self,  color: color)
        case .center, .full:
            CenterTileView(side: self,  color: color)
        case .nudgeTopUp, .nudgeTopDown, .nudgeBottomUp, .nudgeBottomDown:
            NudgeTileView(side: self, color: color)
        }
    }
}

struct NudgeTileView: View {
    var side: TileShape
    var color: Color
    
    var body: some View {
        Canvas { ctx, size in
            let cornerRadius = min(size.width, size.height) * 0.16
            let rect = CGRect(origin: .zero, size: size)
            let path = RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
            let padding = size.height * 0.50
            
            // Background with opacity
            ctx.fill(path, with: .color(color.opacity(0.2)))
            
            // Padded rectangle based on nudge type
            let paddedRect: CGRect
            let arrowY: CGFloat
            let arrowAngle: Double
            
            switch side {
            case .nudgeTopUp:
                paddedRect = CGRect(x: 0, y: padding, width: size.width, height: size.height - padding)
                arrowY = padding * 0.5
                arrowAngle = 0
            case .nudgeTopDown:
                paddedRect = CGRect(x: 0, y: padding, width: size.width, height: size.height - padding)
                arrowY = padding * 0.5
                arrowAngle = 180
            case .nudgeBottomUp:
                paddedRect = CGRect(x: 0, y: 0, width: size.width, height: size.height - padding)
                arrowY = size.height - (padding * 0.5)
                arrowAngle = 0
            case .nudgeBottomDown:
                paddedRect = CGRect(x: 0, y: 0, width: size.width, height: size.height - padding)
                arrowY = size.height - (padding * 0.5)
                arrowAngle = 180
            default:
                paddedRect = rect
                arrowY = size.height * 0.5
                arrowAngle = 0
            }
            
            let paddedPath = RoundedRectangle(cornerRadius: cornerRadius).path(in: paddedRect)
            ctx.fill(paddedPath, with: .color(color))
            
            // Draw arrow
            let arrowSize = size.width * 0.25
            let arrowX = size.width * 0.5
            drawArrow(ctx: ctx, at: CGPoint(x: arrowX, y: arrowY), size: arrowSize, angle: arrowAngle, color: color)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func drawArrow(ctx: GraphicsContext, at position: CGPoint, size: CGFloat, angle: Double, color: Color) {
        var context = ctx
        context.translateBy(x: position.x, y: position.y)
        context.rotate(by: .degrees(angle))
        
        let arrowPath = Path { path in
            path.move(to: CGPoint(x: 0, y: -size/2))
            path.addLine(to: CGPoint(x: size/3, y: size/4))
            path.addLine(to: CGPoint(x: -size/3, y: size/4))
            path.closeSubpath()
        }
        
        context.fill(arrowPath, with: .color(color))
    }
}

struct CenterTileView: View {
    var side: TileShape
    var color: Color
    
    var body: some View {
        Canvas { ctx, size in
            let cornerRadius = min(size.width, size.height) * 0.16
            let rect = CGRect(origin: .zero, size: size)
            let path = RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
            
            // Background rounded rectangle with opacity
            ctx.fill(path, with: .color(color.opacity(0.2)))
            
            // Center square (50% scaled)
            let centerSize = size.width * 0.5
            let centerOrigin = CGPoint(
                x: (size.width - centerSize) / 2,
                y: (size.height - centerSize) / 2
            )
            let centerRect = CGRect(origin: centerOrigin, size: CGSize(width: centerSize, height: centerSize))
            let centerPath = RoundedRectangle(cornerRadius: cornerRadius * 0.5).path(in: centerRect)
            ctx.fill(centerPath, with: .color(color))
            
            // Draw arrows - scale with size
            let angles: [Double] = side == .center ? [225, 315, 135, 45] : [45, 125, 315, 225]
            let arrowSize: CGFloat = size.width * 0.15 // 15% of width
            let padding: CGFloat = size.width * 0.08 // 8% of width
            
            let positions: [CGPoint] = [
                CGPoint(x: padding + arrowSize/2, y: padding + arrowSize/2), // Top-left
                CGPoint(x: size.width - padding - arrowSize/2, y: padding + arrowSize/2), // Top-right
                CGPoint(x: padding + arrowSize/2, y: size.height - padding - arrowSize/2), // Bottom-left
                CGPoint(x: size.width - padding - arrowSize/2, y: size.height - padding - arrowSize/2) // Bottom-right
            ]
            
            for (i, angle) in angles.enumerated() {
                drawArrow(ctx: ctx, at: positions[i], size: arrowSize, angle: angle, color: color)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func drawArrow(ctx: GraphicsContext, at position: CGPoint, size: CGFloat, angle: Double, color: Color) {
        var context = ctx
        context.translateBy(x: position.x, y: position.y)
        context.rotate(by: .degrees(angle))
        
        // Simple arrow shape (triangle pointing left)
        let arrowPath = Path { path in
            path.move(to: CGPoint(x: -size/2, y: 0))
            path.addLine(to: CGPoint(x: size/4, y: -size/3))
            path.addLine(to: CGPoint(x: size/4, y: size/3))
            path.closeSubpath()
        }
        
        context.fill(arrowPath, with: .color(color))
    }
}
    
struct HorizontalTileSideView: View {
    var side: TileShape
    var color: Color
    
    var body: some View {
        Canvas { ctx, size in
            let cornerRadius = min(size.width, size.height) * 0.16
            let halfWidth = size.width / 2
            let rect = CGRect(origin: .zero, size: size)
            let fullPath = RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
            
            // Left half
            var leftCtx = ctx
            leftCtx.clip(to: Path(CGRect(x: 0, y: 0, width: halfWidth, height: size.height)))
            leftCtx.fill(fullPath, with: .color(color.opacity(side == .left ? 1.0 : 0.2)))
            
            // Right half
            var rightCtx = ctx
            rightCtx.clip(to: Path(CGRect(x: halfWidth, y: 0, width: halfWidth, height: size.height)))
            rightCtx.fill(fullPath, with: .color(color.opacity(side == .right ? 1.0 : 0.2)))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
    
#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            TileShape.right.view(color: .blue)
                .frame(width: 50, height: 50)
            TileShape.left.view(color: .blue)
                .frame(width: 50, height: 50)
        }
        HStack(spacing: 16) {
            TileShape.center.view(color: .blue)
                .frame(width: 50, height: 50)
            TileShape.full.view(color: .blue)
                .frame(width: 50, height: 50)
        }
        HStack(spacing: 16) {
            TileShape.nudgeTopUp.view(color: .blue)
                .frame(width: 50, height: 50)
            TileShape.nudgeTopDown.view(color: .blue)
                .frame(width: 50, height: 50)
        }
        HStack(spacing: 16) {
            TileShape.nudgeBottomUp.view(color: .blue)
                .frame(width: 50, height: 50)
            TileShape.nudgeBottomDown.view(color: .blue)
                .frame(width: 50, height: 50)
        }
    }
    .frame(width: 300, height: 300)
}
