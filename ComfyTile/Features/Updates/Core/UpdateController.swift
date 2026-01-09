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
            if !isRunningFromXcode() {
                updater.checkForUpdates()
            } else {
                ComfyLogger.Updater.insert("Skipped Checking For Updates as we are in Xcode")
            }
        } catch {
            print("Failed To Start Update Controller: \(error.localizedDescription)")
            ComfyLogger.Updater.insert("Failed To Start Update Controller: \(error.localizedDescription)")
        }
    }
    
    
    /// This lets us know if we're running in xcode or not
    /// We can compare by letting the output of ComfyLogger.Updater run in archived vs xcode and
    /// use a diff checker to find this
    func isRunningFromXcode() -> Bool {
//        for (key, value) in ProcessInfo.processInfo.environment.sorted(by: { $0.key < $1.key }) {
//            ComfyLogger.Updater.insert("\(key) = \(value)")
//        }
        let env = ProcessInfo.processInfo.environment
        
        if env["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil { return true }
        
        // fallback: DerivedData in DYLD paths
        let dyldKeys = ["DYLD_FRAMEWORK_PATH", "DYLD_LIBRARY_PATH", "__XPC_DYLD_FRAMEWORK_PATH", "__XPC_DYLD_LIBRARY_PATH"]
        for k in dyldKeys {
            if let v = env[k], v.contains("/Library/Developer/Xcode/DerivedData/") {
                return true
            }
        }
        
        return false
    }
    
}
