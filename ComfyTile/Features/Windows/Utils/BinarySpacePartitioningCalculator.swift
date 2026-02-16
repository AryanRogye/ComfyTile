//
//  BinarySpacePartitioningCalculator.swift
//  ComfyTile
//
//  Created by Codex on 2/15/26.
//

import CoreGraphics
import Foundation

enum BinarySpacePartitioningCalculator {
    private static let tolerance: CGFloat = 0.5
    private static let minPartitionEdge: CGFloat = 1
    
    struct AlignedLayout {
        let occupiedRegions: [CGRect]
        let gapRegions: [CGRect]
        let ownerRegions: [Int: CGRect]
    }
    
    static func alignedLayout(occupiedFrames: [CGRect], in bounds: CGRect) -> AlignedLayout {
        let normalizedBounds = bounds.standardized
        guard normalizedBounds.width > minPartitionEdge, normalizedBounds.height > minPartitionEdge else {
            return .init(occupiedRegions: [], gapRegions: [], ownerRegions: [:])
        }
        
        let occupied = occupiedFrames.compactMap { frame -> CGRect? in
            let clipped = frame.standardized.intersection(normalizedBounds).standardized
            guard !clipped.isNull, !clipped.isEmpty else { return nil }
            return clipped
        }
        
        guard !occupied.isEmpty else {
            return .init(occupiedRegions: [], gapRegions: [normalizedBounds], ownerRegions: [:])
        }
        
        var ownerRegions: [Int: CGRect] = [:]
        assignStrictRegions(
            indices: Array(occupied.indices),
            frames: occupied,
            in: normalizedBounds,
            ownerRegions: &ownerRegions
        )
        
        ownerRegions = snapOwnerRegionsToPixelGrid(ownerRegions, in: normalizedBounds)
        
        let alignedOccupied = ownerRegions
            .keys
            .sorted()
            .compactMap { ownerRegions[$0]?.standardized }
        
        return .init(
            occupiedRegions: alignedOccupied,
            gapRegions: [],
            ownerRegions: ownerRegions
        )
    }
    
    private static func assignStrictRegions(
        indices: [Int],
        frames: [CGRect],
        in region: CGRect,
        ownerRegions: inout [Int: CGRect]
    ) {
        guard !indices.isEmpty else { return }
        
        let normalizedRegion = region.standardized
        guard normalizedRegion.width > minPartitionEdge, normalizedRegion.height > minPartitionEdge else {
            assignEvenSlices(
                indices: indices,
                frames: frames,
                in: normalizedRegion,
                ownerRegions: &ownerRegions
            )
            return
        }
        
        if indices.count == 1, let owner = indices.first {
            ownerRegions[owner] = normalizedRegion
            return
        }
        
        guard let split = chooseSplit(
            indices: indices,
            frames: frames,
            in: normalizedRegion
        ) else {
            assignEvenSlices(
                indices: indices,
                frames: frames,
                in: normalizedRegion,
                ownerRegions: &ownerRegions
            )
            return
        }
        
        let regions = splitRegion(
            normalizedRegion,
            axis: split.axis,
            coordinate: split.coordinate
        )
        
        assignStrictRegions(
            indices: split.leftIndices,
            frames: frames,
            in: regions.left,
            ownerRegions: &ownerRegions
        )
        assignStrictRegions(
            indices: split.rightIndices,
            frames: frames,
            in: regions.right,
            ownerRegions: &ownerRegions
        )
    }
    
    private static func chooseSplit(
        indices: [Int],
        frames: [CGRect],
        in region: CGRect
    ) -> SplitCandidate? {
        let xCandidate = evaluateSplit(indices: indices, frames: frames, in: region, axis: .x)
        let yCandidate = evaluateSplit(indices: indices, frames: frames, in: region, axis: .y)
        
        switch (xCandidate, yCandidate) {
        case let (.some(x), .none):
            return x
        case let (.none, .some(y)):
            return y
        case let (.some(x), .some(y)):
            if abs(x.score - y.score) <= tolerance {
                return region.width >= region.height ? x : y
            }
            return x.score > y.score ? x : y
        case (.none, .none):
            return nil
        }
    }
    
    private static func evaluateSplit(
        indices: [Int],
        frames: [CGRect],
        in region: CGRect,
        axis: Axis
    ) -> SplitCandidate? {
        let sorted = indices.sorted { lhs, rhs in
            center(of: frames[lhs], along: axis) < center(of: frames[rhs], along: axis)
        }
        
        guard sorted.count > 1 else { return nil }
        
        var splitIndex = sorted.count / 2
        var bestGap: CGFloat = -1
        
        for index in 1..<sorted.count {
            let leadingCenter = center(of: frames[sorted[index - 1]], along: axis)
            let trailingCenter = center(of: frames[sorted[index]], along: axis)
            let gap = trailingCenter - leadingCenter
            if gap > bestGap {
                bestGap = gap
                splitIndex = index
            }
        }
        
        if bestGap < tolerance {
            splitIndex = sorted.count / 2
            bestGap = 0
        }
        
        let leftIndices = Array(sorted.prefix(splitIndex))
        let rightIndices = Array(sorted.suffix(from: splitIndex))
        guard !leftIndices.isEmpty, !rightIndices.isEmpty else { return nil }
        
        let leftMaxEdge = leftIndices.map { maxEdge(of: frames[$0], along: axis) }.max() ?? 0
        let rightMinEdge = rightIndices.map { minEdge(of: frames[$0], along: axis) }.min() ?? 0
        let leftMaxCenter = leftIndices.map { center(of: frames[$0], along: axis) }.max() ?? 0
        let rightMinCenter = rightIndices.map { center(of: frames[$0], along: axis) }.min() ?? 0
        
        var coordinate: CGFloat
        if leftMaxEdge + tolerance < rightMinEdge {
            coordinate = (leftMaxEdge + rightMinEdge) / 2
        } else {
            coordinate = (leftMaxCenter + rightMinCenter) / 2
        }
        
        let minCoordinate = minEdge(of: region, along: axis) + minPartitionEdge
        let maxCoordinate = maxEdge(of: region, along: axis) - minPartitionEdge
        guard minCoordinate < maxCoordinate else { return nil }
        
        coordinate = round(min(max(coordinate, minCoordinate), maxCoordinate))
        
        let splitRegions = splitRegion(region, axis: axis, coordinate: coordinate)
        let isValid: Bool
        switch axis {
        case .x:
            isValid = splitRegions.left.width > minPartitionEdge &&
                splitRegions.right.width > minPartitionEdge
        case .y:
            isValid = splitRegions.left.height > minPartitionEdge &&
                splitRegions.right.height > minPartitionEdge
        }
        
        guard isValid else { return nil }
        
        return .init(
            axis: axis,
            coordinate: coordinate,
            leftIndices: leftIndices,
            rightIndices: rightIndices,
            score: bestGap
        )
    }
    
    private static func assignEvenSlices(
        indices: [Int],
        frames: [CGRect],
        in region: CGRect,
        ownerRegions: inout [Int: CGRect]
    ) {
        let axis: Axis = region.width >= region.height ? .x : .y
        let sorted = indices.sorted { lhs, rhs in
            center(of: frames[lhs], along: axis) < center(of: frames[rhs], along: axis)
        }
        
        let count = CGFloat(sorted.count)
        guard count > 0 else { return }
        
        let axisEdges: [CGFloat]
        switch axis {
        case .x:
            axisEdges = evenEdges(start: region.minX, end: region.maxX, parts: sorted.count)
        case .y:
            axisEdges = evenEdges(start: region.minY, end: region.maxY, parts: sorted.count)
        }
        
        for (offset, index) in sorted.enumerated() {
            let edgeStart = axisEdges[offset]
            let edgeEnd = axisEdges[offset + 1]
            
            let assignedRect: CGRect
            switch axis {
            case .x:
                assignedRect = CGRect(
                    x: edgeStart,
                    y: region.minY,
                    width: edgeEnd - edgeStart,
                    height: region.height
                )
            case .y:
                assignedRect = CGRect(
                    x: region.minX,
                    y: edgeStart,
                    width: region.width,
                    height: edgeEnd - edgeStart
                )
            }
            
            ownerRegions[index] = assignedRect.standardized
        }
    }
    
    private static func evenEdges(start: CGFloat, end: CGFloat, parts: Int) -> [CGFloat] {
        guard parts > 0 else { return [start, end] }
        
        var edges: [CGFloat] = []
        edges.reserveCapacity(parts + 1)
        edges.append(start)
        
        for index in 1..<parts {
            let ratio = CGFloat(index) / CGFloat(parts)
            edges.append((start + ((end - start) * ratio)).rounded())
        }
        
        edges.append(end)
        
        for index in 1..<edges.count {
            if edges[index] < edges[index - 1] {
                edges[index] = edges[index - 1]
            }
        }
        
        return edges
    }
    
    private static func splitRegion(
        _ region: CGRect,
        axis: Axis,
        coordinate: CGFloat
    ) -> (left: CGRect, right: CGRect) {
        switch axis {
        case .x:
            let left = CGRect(
                x: region.minX,
                y: region.minY,
                width: coordinate - region.minX,
                height: region.height
            ).standardized
            let right = CGRect(
                x: coordinate,
                y: region.minY,
                width: region.maxX - coordinate,
                height: region.height
            ).standardized
            return (left, right)
        case .y:
            let bottom = CGRect(
                x: region.minX,
                y: region.minY,
                width: region.width,
                height: coordinate - region.minY
            ).standardized
            let top = CGRect(
                x: region.minX,
                y: coordinate,
                width: region.width,
                height: region.maxY - coordinate
            ).standardized
            return (bottom, top)
        }
    }
    
    private static func center(of rect: CGRect, along axis: Axis) -> CGFloat {
        switch axis {
        case .x: return rect.midX
        case .y: return rect.midY
        }
    }
    
    private static func minEdge(of rect: CGRect, along axis: Axis) -> CGFloat {
        switch axis {
        case .x: return rect.minX
        case .y: return rect.minY
        }
    }
    
    private static func maxEdge(of rect: CGRect, along axis: Axis) -> CGFloat {
        switch axis {
        case .x: return rect.maxX
        case .y: return rect.maxY
        }
    }
    
    private static func snapOwnerRegionsToPixelGrid(
        _ ownerRegions: [Int: CGRect],
        in bounds: CGRect
    ) -> [Int: CGRect] {
        guard !ownerRegions.isEmpty else { return ownerRegions }
        
        let regions = Array(ownerRegions.values)
        let xBoundaries = uniqueSorted(
            [bounds.minX, bounds.maxX] + regions.flatMap { [$0.minX, $0.maxX] }
        )
        let yBoundaries = uniqueSorted(
            [bounds.minY, bounds.maxY] + regions.flatMap { [$0.minY, $0.maxY] }
        )
        
        let snappedX = snapBoundaries(xBoundaries, lowerBound: bounds.minX, upperBound: bounds.maxX)
        let snappedY = snapBoundaries(yBoundaries, lowerBound: bounds.minY, upperBound: bounds.maxY)
        
        var snapped: [Int: CGRect] = [:]
        snapped.reserveCapacity(ownerRegions.count)
        
        for (owner, rect) in ownerRegions {
            let minX = snappedX[nearestBoundaryIndex(of: rect.minX, in: xBoundaries)]
            let maxX = snappedX[nearestBoundaryIndex(of: rect.maxX, in: xBoundaries)]
            let minY = snappedY[nearestBoundaryIndex(of: rect.minY, in: yBoundaries)]
            let maxY = snappedY[nearestBoundaryIndex(of: rect.maxY, in: yBoundaries)]
            
            snapped[owner] = CGRect(
                x: min(minX, maxX),
                y: min(minY, maxY),
                width: max(0, maxX - minX),
                height: max(0, maxY - minY)
            ).standardized
        }
        
        return snapped
    }
    
    private static func uniqueSorted(_ values: [CGFloat]) -> [CGFloat] {
        let sorted = values.sorted()
        var unique: [CGFloat] = []
        
        for value in sorted {
            guard let last = unique.last else {
                unique.append(value)
                continue
            }
            
            if abs(last - value) > tolerance {
                unique.append(value)
            }
        }
        
        return unique
    }
    
    private static func snapBoundaries(
        _ boundaries: [CGFloat],
        lowerBound: CGFloat,
        upperBound: CGFloat
    ) -> [CGFloat] {
        guard boundaries.count > 1 else { return boundaries }
        
        var snapped = boundaries
        snapped[0] = lowerBound
        snapped[snapped.count - 1] = upperBound
        
        if boundaries.count > 2 {
            for index in 1..<(boundaries.count - 1) {
                let rounded = boundaries[index].rounded()
                let clamped = min(max(rounded, snapped[index - 1]), upperBound)
                snapped[index] = clamped
            }
        }
        
        for index in 1..<snapped.count {
            if snapped[index] < snapped[index - 1] {
                snapped[index] = snapped[index - 1]
            }
        }
        
        for index in stride(from: snapped.count - 2, through: 0, by: -1) {
            if snapped[index] > snapped[index + 1] {
                snapped[index] = snapped[index + 1]
            }
        }
        
        snapped[0] = lowerBound
        snapped[snapped.count - 1] = upperBound
        return snapped
    }
    
    private static func nearestBoundaryIndex(of value: CGFloat, in boundaries: [CGFloat]) -> Int {
        var bestIndex = 0
        var bestDistance = CGFloat.greatestFiniteMagnitude
        
        for (index, boundary) in boundaries.enumerated() {
            let distance = abs(boundary - value)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }
        
        return bestIndex
    }
    
    private enum Axis {
        case x
        case y
    }
    
    private struct SplitCandidate {
        let axis: Axis
        let coordinate: CGFloat
        let leftIndices: [Int]
        let rightIndices: [Int]
        let score: CGFloat
    }
}
