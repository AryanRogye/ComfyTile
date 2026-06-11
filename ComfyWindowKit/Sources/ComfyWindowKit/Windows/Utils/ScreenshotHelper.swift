//
//  ScreenshotHelper.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 11/2/25.
//

import AppKit
import ScreenCaptureKit
import CoreImage

enum ScreenshotError: Error {
    case notFound
    case timedOut
    case captureFailure
}

actor ScreenshotHelper {
    
    struct ScreenshotInfo: Hashable {
        let image : CGImage
        let time: Date
        
        init(_ image: CGImage) {
            self.image = image
            self.time = .now
        }
        
        public func hasBeen2Mins(now: Date = .now) -> Bool {
            return now.timeIntervalSince(time) > 120
        }
    }

    static var cache: [CGWindowID: ScreenshotInfo] = [:]
    
    private static var cleanupTask: Task<Void, Never>?
    
    static func startCacheCleanupLoop() {
        guard cleanupTask == nil else { return }
        
        cleanupTask = Task.detached(priority: .background) {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(7200))
                await clearExpiredCache()
            }
        }
    }
    
    static func stopCacheCleanupLoop() {
        cleanupTask?.cancel()
        cleanupTask = nil
    }
    
    static func clearExpiredCache(now: Date = .now) async {
        cache = cache.filter { _, info in
            !info.hasBeen2Mins(now: now)
        }
        print("Screenshot cache size after cleanup:", cache.count)
    }
    
    static func clearAllCache() {
        cache.removeAll()
        print("Screenshot cache fully cleared")
    }

    
    /// Captures a screenshot of the specified window, trying private API first then falling back to SCK
    static func capture(windowID: CGWindowID, timeoutMs: UInt64 = 1000) async throws -> CGImage {
        
        if let info = cache[windowID] {
            /// if < 2 mins ago, just return the same image
            if !info.hasBeen2Mins() {
                return info.image
            }
        }
        
        // Try private CGSHWCaptureWindowList first (works for everything, instant)
        if let image = await capturePrivateAPI(windowID: windowID) {
            cache[windowID] = ScreenshotInfo(image)
            return image
        }
        
        // Fallback to ScreenCaptureKit if private API fails
        do {
            let image = try await captureSCK(windowID: windowID, timeoutMs: timeoutMs)
            /// store in the cache
            cache[windowID] = ScreenshotInfo(image)
            return image
        } catch {
            throw ScreenshotError.captureFailure
        }
    }
    
    /// Try to capture using private CGSHWCaptureWindowList API (most reliable)
    private static func capturePrivateAPI(windowID: CGWindowID) async -> CGImage? {
        await MainActor.run {
            let cid = CGSMainConnectionID()
            var wid = UInt32(windowID)
            let options: CGSWindowCaptureOptions = [.bestResolution, .fullSize]
            
            // 1. Call the function and get the Unmanaged Core Foundation array
            guard let unmanagedArray = CGSHWCaptureWindowList(
                cid,
                &wid,
                1,
                options.rawValue
            ) else {
                // Function returned nil
                return nil
            }
            
            // 2. Take ownership of the C object (moves it to ARC)
            //    and bridge it to a Swift [CGImage] array.
            guard let images = unmanagedArray.takeRetainedValue() as? [CGImage],
                  let image = images.first else {
                // Bridging failed or the array was empty
                return nil
            }
            
            return image
        }
    }
    
    /// Try to capture using ScreenCaptureKit (fallback)
    private static func captureSCK(windowID: CGWindowID, timeoutMs: UInt64) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
        guard let window = content.windows.first(where: { $0.windowID == windowID }) else {
            throw ScreenshotError.notFound
        }
        
        let screen = NSScreen.screens.first { $0.frame.contains(CGPoint(x: window.frame.midX, y: window.frame.midY)) } ?? .main
        let scale = screen?.backingScaleFactor ?? 1.0
        
        let cfg = SCStreamConfiguration()
        cfg.width = max(1, Int(window.frame.width * scale))
        cfg.height = max(1, Int(window.frame.height * scale))
        cfg.pixelFormat = kCVPixelFormatType_32BGRA
        cfg.queueDepth = 3
        
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let collector = FrameCollector()
        let stream = SCStream(filter: filter, configuration: cfg, delegate: nil)
        
        try await stream.addStreamOutput(collector, type: .screen, sampleHandlerQueue: .global(qos: .userInitiated))
        try await stream.startCapture()
        
        defer {
            Task {
                try? await stream.stopCapture()
                try? await stream.removeStreamOutput(collector, type: .screen)
            }
        }
        
        return try await withThrowingTaskGroup(of: CGImage?.self) { group in
            group.addTask { try await collector.waitForFrame() }
            group.addTask {
                try await Task.sleep(nanoseconds: timeoutMs * 1_000_000)
                return nil
            }
            
            guard let result = try await group.next(), let image = result else {
                group.cancelAll()
                throw ScreenshotError.timedOut
            }
            
            group.cancelAll()
            return image
        }
    }
    
    private final class FrameCollector: NSObject, SCStreamOutput {
        private var continuation: CheckedContinuation<CGImage, Error>?
        private let context = CIContext(options: [.useSoftwareRenderer: false])
        
        func waitForFrame() async throws -> CGImage {
            try await withCheckedThrowingContinuation { self.continuation = $0 }
        }
        
        func stream(_ stream: SCStream, didOutputSampleBuffer buffer: CMSampleBuffer, of type: SCStreamOutputType) {
            guard type == .screen, let pixelBuffer = buffer.imageBuffer else { return }
            guard CVPixelBufferGetWidth(pixelBuffer) > 1, CVPixelBufferGetHeight(pixelBuffer) > 1 else { return }
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            
            continuation?.resume(returning: cgImage)
            continuation = nil
        }
    }
}
