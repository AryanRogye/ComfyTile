//
//  AppServices.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/24/26.
//

import SwiftData
import Foundation

final class AppServices {
    let container: ModelContainer
    let context: ModelContext

    public init(reset: Bool = false) {
        if reset { Self.resetData() }
        do {
            container = try ModelContainer(for: DisplayInfo.self)
            context = ModelContext(container)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    public static func resetData() {
        let url = URL.applicationSupportDirectory
            .appending(path: "default.store")
        try? FileManager.default.removeItem(at: url)
    }
}
