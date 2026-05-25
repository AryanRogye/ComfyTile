//
//  DisplayObserver.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 5/25/26.
//

import CoreGraphics

final class DisplayObserver {
    let completionHandler: (CGDirectDisplayID, CGDisplayChangeSummaryFlags) -> Void

    init(completionHandler: @escaping (CGDirectDisplayID, CGDisplayChangeSummaryFlags) -> Void) {
        self.completionHandler = completionHandler

        CGDisplayRegisterReconfigurationCallback(
            Self.callback,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    deinit {
        CGDisplayRemoveReconfigurationCallback(
            Self.callback,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    private static let callback: CGDisplayReconfigurationCallBack = { display, flags, userInfo in
        guard let userInfo else { return }

        let observer = Unmanaged<DisplayObserver>
            .fromOpaque(userInfo)
            .takeUnretainedValue()

        observer.completionHandler(display, flags)
    }
}
