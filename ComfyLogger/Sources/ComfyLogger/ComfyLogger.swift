// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Foundation

#if DEBUG
// Extending ComfyLogger.Name allows you to use .Kernel, .Network, etc. directly
extension ComfyLogger.Name {
    static let Kernel = ComfyLogger.Name("Kernel")
    static let Network = ComfyLogger.Name("Network")
    static let Graphics = ComfyLogger.Name("Graphics")
    static let Database = ComfyLogger.Name("Database")
    static let Auth = ComfyLogger.Name("Auth")
}

#Preview {
    ComfyLogger.ComfyLoggerView(
        names: [
            .Kernel,
            .Network,
            .Graphics,
            .Database,
            .Auth
        ]
    )
    .task {
        // --- PHASE 1: SYSTEM BOOT SEQUENCE ---
        let bootSequence: [(ComfyLogger.Name, String)] = [
            (.Kernel, "Initializing ComfyOS Kernel v2.0..."),
            (.Kernel, "Mapping virtual memory: 0x0000 -> 0xFFFF"),
            (.Kernel, "CPU 0: Online (Performance Core)"),
            (.Kernel, "CPU 1: Online (Performance Core)"),
            (.Kernel, "CPU 2: Online (Efficiency Core)"),
            (.Graphics, "Metal Device Detected: Apple M4 Max"),
            (.Graphics, "Precompiling compute shaders (142 pipelines)..."),
            (.Database, "Mounting local store: /var/db/comfy.sqlite"),
            (.Database, "Vacuuming WAL file..."),
            (.Auth, "Reading Secure Enclave..."),
            (.Network, "Interface en0 up. IP: 192.168.1.42"),
            (.Auth, "User Authenticated: Aryan Rogye")
        ]
        
        for (log, msg) in bootSequence {
            // Fast, jittery boot speed
            try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.01...0.15) * 1_000_000_000))
            log.insert(msg)
        }
        
        // --- PHASE 2: LIVE APP SIMULATION ---
        let networkMsgs = [
            "GET /api/v1/config - 200 OK",
            "Socket: Heartbeat received (latency: 12ms)",
            "Downloading asset: texture_atlas_04.png",
            "POST /telemetry - 204 No Content"
        ]
        
        let dbMsgs = [
            "CACHE MISS: key 'user_prefs'",
            "SELECT * FROM messages WHERE unread = true",
            "Writing snapshot to disk..."
        ]
        
        let gpuMsgs = [
            "Texture memory usage: 420MB",
            "Rebuilding render pipeline state [Async]",
            "Frame dropped (18ms violation)"
        ]
        
        // Infinite loop to keep the preview alive
        while true {
            let delay = Double.random(in: 0.2...1.5) // Organic pauses
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            let roll = Int.random(in: 0...100)
            
            if roll < 50 {
                ComfyLogger.Name.Network.insert(networkMsgs.randomElement()!)
            } else if roll < 75 {
                ComfyLogger.Name.Database.insert(dbMsgs.randomElement()!)
            } else if roll < 90 {
                ComfyLogger.Name.Graphics.insert(gpuMsgs.randomElement()!)
            } else {
                ComfyLogger.Name.Kernel.insert("Warning: High memory pressure detected (Warn: 80%)")
            }
        }
    }
}
#endif

@MainActor
public enum ComfyLogger {
    
    public struct ComfyLoggerView: View {
        var names: [ComfyLogger.Name]
        @State private var filterText: String = ""
        
        public init(names: [ComfyLogger.Name]) {
            self.names = names
        }
        
        public var body: some View {
            // Pass the filter text into the AppKit wrapper
            OutlineLogView(names: names, filter: filterText)
                .frame(minWidth: 760, minHeight: 420)
                .searchable(text: $filterText, placement: .automatic, prompt: "Filter by Name")
        }
    }

    enum LogNode: Hashable {
        case category(UUID)          // Name.id
        case entry(UUID, UUID)       // (Name.id, Entry.id)
    }
    
    public struct Entry: Identifiable, Sendable, Hashable {
        public enum Level: String, Sendable { case info, debug, warn, error }
        public let id = UUID()
        public let name: String
        public let date: Date
        public let level: Level
        public let message: String
    }
    
    @Observable
    public final class Name: @unchecked Sendable, Identifiable, Hashable {
        
        public static func == (lhs: ComfyLogger.Name, rhs: ComfyLogger.Name) -> Bool {
            lhs.id == rhs.id &&
            lhs.name == rhs.name
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public let id: UUID = UUID()
        public var name: String
        public var content: [Entry] = []

        private var timestamp: String {
            let df = DateFormatter()
            df.timeStyle = .medium
            df.dateStyle = .none
            return df.string(from: Date())
        }

        public init(_ name: String) {
            self.name = name
        }

        public func insert(
            _ message: @autoclosure () -> Any,
            useDebug: Bool = false,
            level: Entry.Level = .info
        ) {
            content.append(
                .init(
                    name: name,
                    date: .now,
                    level: level,
                    message: "\(message())"
                )
            )
        }
    }
    
}
