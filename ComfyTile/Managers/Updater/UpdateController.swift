//
//  UpdateController.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 1/8/26.
//

import Sparkle
import ComfyLogger

extension ComfyLogger {
    static let Updater = ComfyLogger.Name("Updater")
}

@Observable
final class UpdateController {
    
    @ObservationIgnored
    let updater: SPUUpdater
    
    @ObservationIgnored
    let userDriver: UpdateUserDriver
    
    let updaterVM = UpdaterViewModel()
    
    init() {
        userDriver = UpdateUserDriver(
            vm: updaterVM
        )
        updater = SPUUpdater(
            hostBundle: .main,
            applicationBundle: .main,
            userDriver: userDriver,
            delegate: nil
        )
        do {
            try updater.start()
#if DEBUG
#else
            updater.checkForUpdates()
#endif
        } catch {
            print("Failed To Start Update Controller: \(error.localizedDescription)")
            ComfyLogger.Updater.insert("Failed To Start Update Controller: \(error.localizedDescription)")
        }
    }
}
