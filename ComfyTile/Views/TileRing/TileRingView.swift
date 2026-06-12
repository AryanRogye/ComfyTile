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
    
    public static func tileSide(for normalized: CGFloat) -> TileRingSide {
        switch normalized {
        case 337.5..<360, 0..<22.5: return .right
        case 22.5..<67.5: return .bottomRight
        case 67.5..<112.5: return .bottom
        case 112.5..<157.5: return .bottomLeft
        case 157.5..<202.5: return .left
        case 202.5..<247.5: return .topLeft
        case 247.5..<292.5: return .top
        case 292.5..<337.5: return .topRight
        default: return .none
        }
    }
}

struct TileRingView: View {
    
    @Bindable var vm: TileRingViewModel
    
    private static let slices = makeSlices(8)
    
    var indexOut: Int {
        vm.currentTile.rawValue
    }

    var body: some View {
        ZStack {
            content
            
            if let box = vm.debugBox {
                Circle()
                    .stroke(.red, lineWidth: 2)
                    .frame(width: box.width, height: box.height)
                    .position(x: box.midX, y: box.midY)
            }
            
            if let mouse = vm.debugMousePoint {
                Circle()
                    .fill(.blue)
                    .frame(width: 10, height: 10)
                    .position(x: mouse.x, y: mouse.y)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var content: some View {
        ZStack {
            
            /// Main Outer Circle
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
                    .animation(.spring, value: indexOut)
                }
            }
            .frame(
                width: vm.diameter + 100,
                height: vm.diameter + 100
            )
            
            /// Full Screen
            ZStack {
                Circle()
                    .stroke(
                        Color.white.opacity(0.2),
                        lineWidth: 10
                    )
            }
            .frame(
                width: vm.diameter - 10,
                height: vm.diameter - 10
            )
        }
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
    TileRingView(vm: TileRingViewModel())
        .frame(width: 320, height: 320)
        .background(.gray)
}
