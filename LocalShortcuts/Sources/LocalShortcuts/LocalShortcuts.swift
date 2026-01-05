import AppKit

public enum LocalShortcuts {
    public struct Name: Hashable, Codable {
        
        public typealias Handler = () -> Void
        typealias LocalMonitor = Any
        public let rawValue: String
        public let defaultShortcut: Shortcut

        @MainActor internal static var monitor: LocalMonitor?
        
        @MainActor internal static var shortcuts: [Name: Shortcut] = [:]
        @MainActor internal static var handlers:  [Name: Handler] = [:]
        
        /// Registers with null
        @MainActor public init(_ rawValue: String, _ shortcut: Shortcut) {
            self.rawValue = rawValue
            self.defaultShortcut = shortcut
            Self.shortcuts[self] = shortcut
        }
        
        @MainActor public static func onKeyDown(
            for name: Name,
            completion: @escaping Handler
        ) {
            handlers[name] = completion
            startMonitorIfNeeded()
        }
        
        @MainActor private static func startMonitorIfNeeded() {
            guard Name.monitor == nil else { return }
            
            Name.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                handle(event: event)
                return event
            }
        }
        
        @MainActor private static func handle(event: NSEvent) {
            guard let eventShortcut = Shortcut.from(event: event) else { return }
            
            // find the first name whose bound shortcut matches this event
            guard let (name, _) = shortcuts.first(where: { $0.value == eventShortcut }),
                  let handler = handlers[name] else {
                return
            }
            
            handler()
        }
    }
    
    public struct Shortcut: Codable, Hashable {
        let modifier: [Modifier]
        let keys: [Key]
        
        public init(modifier: [Modifier], keys: [Key]) {
            self.modifier = modifier
            self.keys = keys
        }
        
        /// Convenience to build a shortcut from an event. Returns `nil` if no key could be parsed.
        @MainActor public static func from(event: NSEvent) -> Shortcut? {
            let modifiers = LocalShortcuts.Modifier.activeModifiers(from: event)
            let keys = LocalShortcuts.Key.activeKeys(event: event)
            
            guard !keys.isEmpty else { return nil }
            return Shortcut(modifier: modifiers, keys: keys)
        }
        
        /// Backwards-compatible helper; prefer `from(event:)` when you need to validate.
        @MainActor public static func getShortcut(event: NSEvent) -> Shortcut {
            if let shortcut = from(event: event) {
                return shortcut
            }
            
            // Fallback to the previous behavior (empty keys) so existing callers keep working.
            let modifiers = LocalShortcuts.Modifier.activeModifiers(from: event)
            let keys = LocalShortcuts.Key.activeKeys(event: event)
            
            return Shortcut(modifier: modifiers, keys: keys)
        }
        
        @MainActor
        public func modifiers() -> String {
            modifier.map { $0.rawValue }.joined()
        }
        
        @MainActor
        public func keyValues() -> String {
            keys.map { $0.rawValue }.joined()
        }
        
        /// Human-friendly representation used in UI labels.
        @MainActor
        public func displayValue() -> String {
            [modifiers(), keyValues()]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }
}
