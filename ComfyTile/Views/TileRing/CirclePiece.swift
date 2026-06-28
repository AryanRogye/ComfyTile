//
//  CirclePiece.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/11/26.
//

import SwiftUI

struct CirclePiece: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = max(outerRadius - thickness, 0)

        // Outer arc
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        // Inner arc (reverse)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )

        path.closeSubpath()
        return path
    }
}
