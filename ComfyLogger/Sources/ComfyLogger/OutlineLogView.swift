//
//  OutlineLogView.swift
//  ComfyLogger
//
//  Created by Aryan Rogye on 1/7/26.
//

import Foundation
import SwiftUI
import AppKit

// MARK: - Color Extension
extension ComfyLogger.Entry.Level {
    var color: NSColor {
        switch self {
        case .info: return .labelColor
        case .debug: return .secondaryLabelColor
        case .warn: return .systemOrange
        case .error: return .systemRed
        }
    }
}

extension ComfyLogger {
    
    public struct OutlineLogView: NSViewRepresentable {
        
        public var names: [ComfyLogger.Name]
        public var filter: String
        
        public init(names: [ComfyLogger.Name], filter: String) {
            self.names = names
            self.filter = filter
        }
        
        public func makeCoordinator() -> Coordinator { Coordinator() }
        
        public func makeNSView(context: Context) -> NSScrollView {
            // Use our custom subclass that supports Copy/Paste
            let outline = LogOutlineView()
            
            // Layout & Style
            outline.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
            outline.rowHeight = 24
            outline.floatsGroupRows = true
            outline.usesAlternatingRowBackgroundColors = true
            outline.selectionHighlightStyle = .regular
            outline.allowsMultipleSelection = true
            outline.autosaveExpandedItems = true
            outline.headerView = NSTableHeaderView()
            
            // Columns
            let (colLevel, colMsg, colTime) = createColumns()
            outline.addTableColumn(colLevel)
            outline.addTableColumn(colMsg)
            outline.addTableColumn(colTime)
            outline.outlineTableColumn = colMsg
            
            // Data Connection
            outline.delegate = context.coordinator
            outline.dataSource = context.coordinator
            
            // Hook up the context menu
            outline.menu = context.coordinator.createContextMenu()
            
            let scroll = NSScrollView()
            scroll.hasVerticalScroller = true
            scroll.documentView = outline
            
            context.coordinator.outlineView = outline
            
            // Initial update
            context.coordinator.update(names: names, filter: filter)
            
            return scroll
        }
        
        private func createColumns() -> (NSTableColumn, NSTableColumn, NSTableColumn) {
            let colLevel = NSTableColumn(identifier: .init("level"))
            colLevel.title = "Lvl"
            colLevel.width = 45
            colLevel.minWidth = 40
            colLevel.maxWidth = 60
            colLevel.resizingMask = .userResizingMask
            
            let colMsg = NSTableColumn(identifier: .init("message"))
            colMsg.title = "Message"
            colMsg.width = 500
            colMsg.minWidth = 200
            colMsg.resizingMask = [.autoresizingMask, .userResizingMask]
            
            let colTime = NSTableColumn(identifier: .init("time"))
            colTime.title = "Time"
            colTime.width = 90
            colTime.minWidth = 80
            colTime.maxWidth = 120
            colTime.resizingMask = .userResizingMask
            
            return (colLevel, colMsg, colTime)
        }
        
        public func updateNSView(_ nsView: NSScrollView, context: Context) {
            context.coordinator.update(names: names, filter: filter)
            
            // Reload logic
            context.coordinator.outlineView?.reloadData()
            
            // Auto-expand if searching
            if !filter.isEmpty {
                context.coordinator.outlineView?.expandItem(nil, expandChildren: true)
            }
        }
        
        // MARK: - Coordinator
        
        @MainActor
        public final class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, NSMenuItemValidation {
            
            weak var outlineView: LogOutlineView?
            
            // Data
            private var names: [ComfyLogger.Name] = []
            private var namesByID: [UUID: ComfyLogger.Name] = [:]
            private var entriesByKey: [UUID: [UUID: ComfyLogger.Entry]] = [:]
            
            // State
            private var expandedEntryIDs: Set<UUID> = []
            
            // Font cache for height calculation
            private let msgFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            
            func update(names: [ComfyLogger.Name], filter: String) {
                if filter.isEmpty {
                    self.names = names
                } else {
                    // Filter categories by name or by any entry's message, but keep original instances
                    self.names = names.filter { cat in
                        if cat.name.localizedCaseInsensitiveContains(filter) { return true }
                        return cat.content.contains { $0.message.localizedCaseInsensitiveContains(filter) }
                    }
                }
                
                self.namesByID = Dictionary(uniqueKeysWithValues: self.names.map { ($0.id, $0) })
                self.entriesByKey = Dictionary(uniqueKeysWithValues: self.names.map { n in
                    (n.id, Dictionary(uniqueKeysWithValues: n.content.map { ($0.id, $0) }))
                })
            }
            
            // MARK: - Context Menu & Copy
            
            func createContextMenu() -> NSMenu {
                let menu = NSMenu()
                menu.addItem(NSMenuItem(title: "Copy Message", action: #selector(copyMessage(_:)), keyEquivalent: "c"))
                menu.addItem(NSMenuItem(title: "Copy All Info", action: #selector(copyAllInfo(_:)), keyEquivalent: ""))
                return menu
            }
            
            // Handle standard Cmd+C from the custom view
            @objc func copy(_ sender: Any?) {
                copyMessage(sender)
            }
            
            @objc func copyMessage(_ sender: Any?) {
                copyToClipboard(fullDetails: false)
            }
            
            @objc func copyAllInfo(_ sender: Any?) {
                copyToClipboard(fullDetails: true)
            }
            
            private func copyToClipboard(fullDetails: Bool) {
                guard let outlineView = outlineView else { return }
                let selectedRows = outlineView.selectedRowIndexes
                guard !selectedRows.isEmpty else { return }
                
                var strings: [String] = []
                
                selectedRows.forEach { row in
                    if let item = outlineView.item(atRow: row) as? LogNode {
                        switch item {
                        case .category(let id):
                            if let name = namesByID[id]?.name {
                                strings.append("[\(name)]")
                            }
                        case .entry(let nameID, let entryID):
                            if let entry = entriesByKey[nameID]?[entryID] {
                                if fullDetails {
                                    strings.append("\(entry.date.formatted()) [\(entry.level.rawValue.uppercased())] \(entry.message)")
                                } else {
                                    strings.append(entry.message)
                                }
                            }
                        }
                    }
                }
                
                let fullString = strings.joined(separator: "\n")
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(fullString, forType: .string)
            }
            
            public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
                return outlineView?.selectedRow ?? -1 >= 0
            }
            
            // MARK: - DataSource
            
            public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
                if item == nil { return names.count }
                guard let node = item as? LogNode else { return 0 }
                
                switch node {
                case .category(let nameID):
                    return namesByID[nameID]?.content.count ?? 0
                case .entry:
                    return 0
                }
            }
            
            public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
                if case .category = item as? LogNode { return true }
                return false
            }
            
            public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
                if item == nil { return LogNode.category(names[index].id) }
                
                guard let node = item as? LogNode else { return LogNode.category(UUID()) }
                
                if case .category(let nameID) = node {
                    if let cat = namesByID[nameID], index < cat.content.count {
                        return LogNode.entry(nameID, cat.content[index].id)
                    }
                }
                return LogNode.category(UUID())
            }
            
            // MARK: - Delegate: Height (The Anti-Jank Logic)
            
            public func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
                guard let node = item as? LogNode else { return 24 }
                
                switch node {
                case .category:
                    return 24
                case .entry(let nameID, let entryID):
                    if !expandedEntryIDs.contains(entryID) { return 24 }
                    
                    guard let entry = entriesByKey[nameID]?[entryID] else { return 24 }
                    
                    // Calculate precise height using TextKit logic (faster/smoother than dummy views)
                    let colIndex = outlineView.column(withIdentifier: NSUserInterfaceItemIdentifier("message"))
                    let width = colIndex >= 0 ? outlineView.tableColumns[colIndex].width : 400
                    let availableWidth = width - 12 // Padding
                    
                    let text = entry.message as NSString
                    let rect = text.boundingRect(
                        with: NSSize(width: availableWidth, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: [.font: msgFont]
                    )
                    
                    return max(24, rect.height + 16) // +16 for vertical padding
                }
            }
            
            // MARK: - Delegate: Views
            
            public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
                guard let node = item as? LogNode else { return nil }
                
                // --- Group Row ---
                if case .category(let nameID) = node {
                    let cellID = NSUserInterfaceItemIdentifier("GroupCell")
                    var cell = outlineView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
                    if cell == nil {
                        cell = makeCell(identifier: cellID)
                        cell?.textField?.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
                        cell?.textField?.textColor = .labelColor
                    }
                    cell?.textField?.stringValue = namesByID[nameID]?.name ?? "Unknown"
                    return cell
                }
                
                // --- Entry Row ---
                guard let tableColumn = tableColumn,
                      case .entry(let nameID, let entryID) = node,
                      let entry = entriesByKey[nameID]?[entryID] else { return nil }
                
                let cellID = NSUserInterfaceItemIdentifier("cell.\(tableColumn.identifier.rawValue)")
                var cell = outlineView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
                if cell == nil {
                    cell = makeCell(identifier: cellID)
                    
                    // Specific styling per column
                    if tableColumn.identifier.rawValue == "message" {
                        cell?.textField?.font = msgFont // Monospaced
                        cell?.textField?.lineBreakMode = .byWordWrapping
                        cell?.textField?.maximumNumberOfLines = 0
                    } else if tableColumn.identifier.rawValue == "level" {
                        cell?.textField?.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)
                    } else {
                        cell?.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
                        cell?.textField?.textColor = .tertiaryLabelColor
                    }
                }
                
                switch tableColumn.identifier.rawValue {
                case "level":
                    cell?.textField?.stringValue = entry.level.rawValue.uppercased()
                    cell?.textField?.textColor = entry.level.color
                case "message":
                    cell?.textField?.stringValue = entry.message
                    cell?.textField?.textColor = .labelColor
                case "time":
                    cell?.textField?.stringValue = entry.date.formatted(date: .omitted, time: .standard)
                default:
                    break
                }
                
                return cell
            }
            
            public func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
                if case .category = item as? LogNode { return true }
                return false
            }
            
            // MARK: - Interaction
            
            public func outlineViewSelectionDidChange(_ notification: Notification) {
                guard let outlineView = notification.object as? NSOutlineView else { return }
                
                let selectedIndex = outlineView.selectedRow
                if selectedIndex < 0 { return }
                
                // If it's a click (not a drag-select), toggle expansion
                // Note: In a real app, you might differentiate between selection and expansion interactions
                // For now, let's say "Double Click" expands? Or single click?
                // Single click is easier for discovery.
                
                guard let item = outlineView.item(atRow: selectedIndex) as? LogNode else { return }
                
                if case .entry(_, let entryID) = item {
                    let isExpanding = !expandedEntryIDs.contains(entryID)
                    
                    if isExpanding {
                        expandedEntryIDs.insert(entryID)
                    } else {
                        expandedEntryIDs.remove(entryID)
                    }
                    
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.2
                        context.allowsImplicitAnimation = true
                        outlineView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: selectedIndex))
                    }
                }
            }
            
            private func makeCell(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
                let cell = NSTableCellView()
                cell.identifier = identifier
                
                let tf = NSTextField(labelWithString: "")
                tf.translatesAutoresizingMaskIntoConstraints = false
                tf.drawsBackground = false
                tf.isBordered = false
                tf.isEditable = false
                tf.isSelectable = false // Row selection handles copy
                
                cell.addSubview(tf)
                cell.textField = tf
                
                NSLayoutConstraint.activate([
                    tf.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                    tf.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                    tf.topAnchor.constraint(equalTo: cell.topAnchor, constant: 2),
                    tf.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -2)
                ])
                
                return cell
            }
        }
    }
    
    // MARK: - Custom Outline View (For Copy Support)
    
    public class LogOutlineView: NSOutlineView {
        
        // This enables standard "Copy" via menu or Cmd+C
        public override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
            return true
        }
        
        // Trap the copy command and send it to our delegate (Coordinator)
        @objc func copy(_ sender: Any?) {
            if let delegate = self.delegate as? OutlineLogView.Coordinator {
                delegate.copy(sender)
            }
        }
        
        // Ensure right-click works for the whole row
        public override func menu(for event: NSEvent) -> NSMenu? {
            let point = self.convert(event.locationInWindow, from: nil)
            let row = self.row(at: point)
            
            // If the user right-clicks a row that isn't selected, select it first
            if row >= 0 && !self.selectedRowIndexes.contains(row) {
                self.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            }
            
            return super.menu(for: event)
        }
    }
}

