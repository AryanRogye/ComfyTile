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
    
    // MARK: - Per-App Profiles
    
    /// bundleID → profile
    var appProfiles: [String: DisplayProfile] = [:]
    var activeAppBundleID: String? = nil
    
    @ObservationIgnored
    private var applyProfileTask: Task<Void, Never>?
    
    init() {
        loadProfiles()
    }
    
    // MARK: - Brightness
    
    var currentBrightness: Float {
        var value: Float = 0
        windowServerBridge.getBrightness?(CGMainDisplayID(), &value)
        return value
    }
    
    func setBrightness(_ value: Float) {
        let clamped = max(0.05, min(value, Float(maxEDRHeadroom)))
        windowServerBridge.setBrightness?(CGMainDisplayID(), clamped)
        if let id = activeAppBundleID {
            appProfiles[id, default: .default].brightness = clamped
            applyGamma(appProfiles[id, default: .default].contrast)
            saveProfiles()
        }
    }
    
    var maxEDRHeadroom: CGFloat {
        NSScreen.main?.maximumPotentialExtendedDynamicRangeColorComponentValue ?? 1.0
    }
    
    // MARK: - Contrast
    
    var contrast: Double {
        get { appProfiles[activeAppBundleID ?? "", default: .default].contrast }
        set {
            guard let id = activeAppBundleID else { return }
            appProfiles[id, default: .default].contrast = newValue
            applyGamma(newValue)
            saveProfiles()
        }
    }
    
    func setContrast(_ value: Double, for bundleID: String) {
        appProfiles[bundleID, default: .default].contrast = value
        saveProfiles()
        if bundleID == activeAppBundleID {
            applyGamma(value)
        }
    }
    
    func resetContrast() {
        if let id = activeAppBundleID {
            appProfiles[id, default: .default].contrast = 1.0
            saveProfiles()
        }
        CGDisplayRestoreColorSyncSettings()
    }
    // MARK: - Private
    
    public func activateApp(bundleID: String) {
        activeAppBundleID = bundleID
        applyProfileTask?.cancel()
        applyProfileTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            self.applyProfile(for: bundleID)
        }
    }
    
    public func applyProfile(for bundleID: String) {
        let profile = appProfiles[bundleID, default: .default]
        windowServerBridge.setBrightness?(CGMainDisplayID(), profile.brightness)
        applyGamma(profile.contrast)
        print("""
        Applying profile for \(bundleID)
        Contrast: \(profile.contrast)
        Brightness: \(profile.brightness)
        """)
    }
    
    private func applyGamma(_ contrast: Double) {
        let displayID = CGMainDisplayID()
        let count = 256
        
        var red   = [CGGammaValue](repeating: 0, count: count)
        var green = [CGGammaValue](repeating: 0, count: count)
        var blue  = [CGGammaValue](repeating: 0, count: count)
        
        for i in 0..<count {
            let normalized = Double(i) / Double(count - 1)
            let adjusted   = pow(normalized, 1.0 / contrast)
            let clamped    = max(0, min(1, adjusted))
            red[i]   = CGGammaValue(clamped)
            green[i] = CGGammaValue(clamped)
            blue[i]  = CGGammaValue(clamped)
        }
        
        CGSetDisplayTransferByTable(displayID, UInt32(count), &red, &green, &blue)
    }
    
    // MARK: - Persistence
    
    private var profilesKey: String { "display.appProfiles" }
    
    private func saveProfiles() {
        guard let data = try? JSONEncoder().encode(appProfiles) else { return }
        UserDefaults.standard.set(data, forKey: profilesKey)
    }
    
    private func loadProfiles() {
        guard let data = UserDefaults.standard.data(forKey: profilesKey),
              let decoded = try? JSONDecoder().decode([String: DisplayProfile].self, from: data)
        else { return }
        appProfiles = decoded
    }
}
