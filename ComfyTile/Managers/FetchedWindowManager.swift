//
//  FetchedWindowManager.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 11/2/25.
//

@Observable @MainActor
final class FetchedWindowManager {
    /// Seed Fetched Windows At Start
    var fetchedWindows : [FetchedWindow] = []
    
    init() {
        Task {
            await loadWindows()
        }
    }
    
    public func loadWindows() async {
        guard let fw = await WindowManagerHelpers.getUserWindows() else { return }
        
        // fast lookup of the newest snapshot by windowID
        let newByID = Dictionary(uniqueKeysWithValues: fw.map { ($0.windowID, $0) })
        
        var merged: [FetchedWindow] = []
        merged.reserveCapacity(fw.count)
        
        // 1) keep current (rearranged) order, but replace each element with the fresh snapshot
        for old in fetchedWindows {
            if let updated = newByID[old.windowID] {
                merged.append(updated)
            }
        }
        
        // 2) append brand new windows that weren't already in your list
        let existingIDs = Set(merged.map { $0.windowID })
        for w in fw where !existingIDs.contains(w.windowID) {
            merged.append(w)
        }
        
        fetchedWindows = merged
    }
}
