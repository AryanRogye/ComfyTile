//
//  TileRingView.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 6/11/26.
//

import SwiftUI

enum TileRingSide: Int {
    case none = -1
    case top = 0
    case topRight = 1
    case right = 2
    case bottomRight = 3
    case bottom = 4
    case bottomLeft = 5
    case left = 6
    case topLeft = 7
}

struct TileRingView: View {
    
    private static let slices = makeSlices(8)
    private let indexOut: Int = TileRingSide.none.rawValue

    var body: some View {
        content
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
    }

    private var content: some View {
        ZStack {
            ForEach(Array(Self.slices.enumerated()), id: \.element.id) { i, slice in
                CirclePiece(
                    startAngle: slice.start,
                    endAngle: slice.end,
                    thickness: 24
                )
                .fill(Color.white.opacity(0.2))
                .stroke(.black)
                .offset(
                    x: slice.index == indexOut ? cos(slice.midAngle.radians) * 15 : 0,
                    y: slice.index == indexOut ? sin(slice.midAngle.radians) * 15 : 0
                )
            }
        }
        .frame(width: 240, height: 240)
    }

    struct SideSlice: Identifiable, Hashable {
        let index: Int
        let start: Angle
        let end: Angle
        var id: Int { index }
        
        var midAngle: Angle {
            Angle(degrees: (start.degrees + end.degrees) / 2)
        }
    }

    static func makeSlices(_ count: Int) -> [SideSlice] {
        guard count > 0 else { return [] }
        
        let sliceSize = 360.0 / Double(count)
        let offset = 270.0 - sliceSize / 2
        
        return (0..<count).map { i in
            let start = Angle(degrees: offset + Double(i) * sliceSize)
            let end   = Angle(degrees: offset + Double(i + 1) * sliceSize)
            return SideSlice(index: i, start: start, end: end)
        }
    }
}

#Preview {
    TileRingView()
        .frame(width: 320, height: 320)
        .background(.gray)
}
