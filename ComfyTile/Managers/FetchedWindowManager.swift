//
//  FetchedWindowManager.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 11/2/25.
//

import TilerProcess

@Observable @MainActor
final class FetchedWindowManager {
    
    @ObservationIgnored var processService: ProcessService?
    /// Seed Fetched Windows At Start
    var fetchedWindows : [FetchedWindow] = []
    var favoriteWindows: [FetchedWindow] = []
    
    init() {
        Task {
            await loadWindows()
        }
    }
    
    public func assignProcessService(_ service: ProcessService) {
        self.processService = service
    }
    
    public func isFavorite(_ window: FetchedWindow) -> Bool {
        return favoriteWindows.contains(window)
    }
    
    public func toggle(_ window: FetchedWindow) {
        if favoriteWindows.contains(window) {
            favoriteWindows.removeAll(where: { $0.windowID == window.windowID })
        } else {
            favoriteWindows.append(window)
        }
    }
    
    public func loadWindows() async {
        guard let processService else { return }
        if let fw = await WindowManagerHelpers.getUserWindows(using: processService) {
            print("FetchedWindow Count: \(fw.count)")
            fetchedWindows = fw
            print("Loaded Fetched Windows")
        }
    }
}
