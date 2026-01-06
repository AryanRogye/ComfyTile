//
//  WindowAnimator.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 10/5/25.
//

@preconcurrency import SwiftUI

enum Ease {
    static func easeInOut(_ t: CGFloat) -> CGFloat {
        t < 0.5 ? 4*t*t*t : 1 - pow(-2*t + 2, 3)/2
    }
}

final class WindowAnimator {
    private var timer: Timer?
    private var startTime: CFTimeInterval = 0
    private var duration: TimeInterval = 0.12
    
    func animate(
        focusedWindow: FocusedWindow,
        to target: CGPoint,
        duration: TimeInterval = 0.12,
        completion: @escaping () -> Void = {}
    ) {
        timer?.invalidate()
        self.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : duration
        
        guard self.duration > 0,
              let start = focusedWindow.windowFrame?.origin else {
            focusedWindow.setPosition(x: target.x, y: target.y)
            completion()
            return
        }
        
        startTime = CACurrentMediaTime()
        let fps: Double = 60
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); completion(); return }
            let now = CACurrentMediaTime()
            let raw = min(1, (now - self.startTime) / self.duration)
            let tt = Ease.easeInOut(CGFloat(raw))
            
            func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
            
            let x = lerp(start.x, target.x, tt)
            let y = lerp(start.y, target.y, tt)
            focusedWindow.setPosition(x: x, y: y)
            
            if raw >= 1 {
                t.invalidate()
                completion()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }
}
