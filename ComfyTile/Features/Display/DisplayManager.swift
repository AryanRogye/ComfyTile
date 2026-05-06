//
//  DisplayManager.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/5/26.
//
import AppKit

@Observable
@MainActor
final class DisplayManager {
    
    let windowServerBridge = WindowServerBridge.shared
    
    // MARK: - Brightness
    
    var currentBrightness: Float {
        var value: Float = 0
        windowServerBridge.getBrightness?(CGMainDisplayID(), &value)
        return value
    }
    
    func setBrightness(_ value: Float) {
        let clamped = max(0.05, min(value, Float(maxEDRHeadroom)))
        windowServerBridge.setBrightness?(CGMainDisplayID(), clamped)
    }
    
    var maxEDRHeadroom: CGFloat {
        NSScreen.main?.maximumPotentialExtendedDynamicRangeColorComponentValue ?? 1.0
    }
    
    // MARK: - Contrast / Gamma
    
    /// 0.5 = low contrast, 1.0 = default, 2.0 = punchy
    var contrast: Double = 1.0 {
        didSet { applyGamma() }
    }
    
    func resetContrast() {
        contrast = 1.0
        CGDisplayRestoreColorSyncSettings()
    }
    
    private func applyGamma() {
        let displayID = CGMainDisplayID()
        let count = 256
        
        var red   = [CGGammaValue](repeating: 0, count: count)
        var green = [CGGammaValue](repeating: 0, count: count)
        var blue  = [CGGammaValue](repeating: 0, count: count)
        
        for i in 0..<count {
            let normalized = Double(i) / Double(count - 1)
            // apply gamma curve: pow(x, 1/contrast) brightens midtones when contrast > 1
            let adjusted = pow(normalized, 1.0 / contrast)
            let clamped  = max(0, min(1, adjusted))
            red[i]   = CGGammaValue(clamped)
            green[i] = CGGammaValue(clamped)
            blue[i]  = CGGammaValue(clamped)
        }
        
        CGSetDisplayTransferByTable(
            displayID,
            UInt32(count),
            &red,
            &green,
            &blue
        )
    }
}
