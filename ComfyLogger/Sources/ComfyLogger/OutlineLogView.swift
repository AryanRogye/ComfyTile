//
//  OutlineLogView.swift
//  ComfyLogger
//
//  Created by Aryan Rogye on 1/7/26.
//

import Foundation
import SwiftUI
import AppKit

extension ComfyLogger.Entry.Level {
    var color: NSColor {
        switch self {
        case .info:  return .labelColor
        case .debug: return .secondaryLabelColor
        case .warn:  return .systemRed
        case .error: return .systemRed
        }
    }
}

extension ComfyLogger {
    
    public struct OutlineLogView: NSViewRepresentable {
        fileprivate static let baseRowHeight: CGFloat = 20
        
        public var names: [ComfyLogger.Name]
        public var filter: String
        
        public init(names: [ComfyLogger.Name], filter: String) {
            self.names = names
            self.filter = filter
        }
        
        public func makeCoordinator() -> Coordinator { .init() }
        
        public func makeNSView(context: Context) -> NSScrollView {
            let outline = LogOutlineView()
            outline.wantsLayer = true
            
            // Style (keep your values)
            outline.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
            outline.rowHeight = Self.baseRowHeight
            outline.floatsGroupRows = true
            outline.usesAlternatingRowBackgroundColors = true
            outline.selectionHighlightStyle = .regular
            outline.allowsMultipleSelection = true
            outline.autosaveExpandedItems = true
            outline.intercellSpacing = NSSize(width: 0, height: 0)
            
            // Header (explicit frame helps in tight containers)
            outline.headerView = NSTableHeaderView(frame: NSRect(x: 0, y: 0, width: 0, height: 24))
            
            // Columns (keep your values)
            let cols = Columns()
            outline.addTableColumn(cols.level)
            outline.addTableColumn(cols.message)
            outline.addTableColumn(cols.time)
            outline.outlineTableColumn = cols.message
            
            // Data hookup
            outline.delegate = context.coordinator
            outline.dataSource = context.coordinator
            outline.menu = context.coordinator.makeMenu()
            
            // ScrollView setup (NO manual outline.frame)
            let scroll = NSScrollView()
            scroll.hasVerticalScroller = true
            scroll.hasHorizontalScroller = true
            scroll.autohidesScrollers = true
            scroll.borderType = .noBorder
            scroll.drawsBackground = false
            
            // This combo prevents header/content fighting in small frames
            scroll.automaticallyAdjustsContentInsets = false
            scroll.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
            scroll.documentView = outline
            
            context.coordinator.outlineView = outline
            context.coordinator.update(names: names, filter: filter)
            outline.reloadData()
            
            // Helps header settle correctly when embedded in SwiftUI
            DispatchQueue.main.async {
                outline.headerView?.needsLayout = true
                outline.headerView?.layoutSubtreeIfNeeded()
            }
            
            return scroll
        }
        
        public func updateNSView(_ nsView: NSScrollView, context: Context) {
            context.coordinator.update(names: names, filter: filter)
            
            guard let outline = context.coordinator.outlineView else { return }
            outline.reloadData()
            
            if !filter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                outline.expandItem(nil, expandChildren: true)
            }
        }
    }
    
    // MARK: - Columns
    
    @MainActor
    private struct Columns {
        let level: NSTableColumn = {
            let c = NSTableColumn(identifier: .init("level"))
            c.title = "Lvl"
            c.width = 45
            c.minWidth = 40
            c.maxWidth = 60
            c.resizingMask = .userResizingMask
            return c
        }()
        
        let message: NSTableColumn = {
            let c = NSTableColumn(identifier: .init("message"))
            c.title = "Message"
            c.width = 500
            c.minWidth = 200
            c.resizingMask = [.autoresizingMask, .userResizingMask]
            return c
        }()
        
        let time: NSTableColumn = {
            let c = NSTableColumn(identifier: .init("time"))
            c.title = "Time"
            c.width = 90
            c.minWidth = 80
            c.maxWidth = 120
            c.resizingMask = .userResizingMask
            return c
        }()
    }
    
    // MARK: - Coordinator
    
    @MainActor
    public final class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, NSMenuItemValidation {
        
        weak var outlineView: LogOutlineView?
        
        // Data
        private var visibleNames: [ComfyLogger.Name] = []
        private var namesByID: [UUID: ComfyLogger.Name] = [:]
        private var entriesByNameID: [UUID: [UUID: ComfyLogger.Entry]] = [:]
        private var visibleEntryIDsByNameID: [UUID: [UUID]] = [:]
        
        // State
        private var expandedEntryIDs: Set<UUID> = []
        
        // Fonts (keep your values)
        private let msgFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        
        // Search helper
        private let timeFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateStyle = .none
            f.timeStyle = .medium
            return f
        }()
        
        func update(names: [ComfyLogger.Name], filter: String) {
            let f = filter.trimmingCharacters(in: .whitespacesAndNewlines)
            let searching = !f.isEmpty
            
            func entryMatches(_ e: ComfyLogger.Entry) -> Bool {
                if e.message.localizedCaseInsensitiveContains(f) { return true }
                if e.level.rawValue.localizedCaseInsensitiveContains(f) { return true }
                if timeFormatter.string(from: e.date).localizedCaseInsensitiveContains(f) { return true }
                return false
            }
            
            var kept: [ComfyLogger.Name] = []
            var visible: [UUID: [UUID]] = [:]
            
            for n in names {
                let allIDs = n.content.map(\.id)
                
                if !searching {
                    kept.append(n)
                    visible[n.id] = allIDs
                    continue
                }
                
                let nameMatch = n.name.localizedCaseInsensitiveContains(f)
                let matchedIDs = nameMatch ? allIDs : n.content.filter(entryMatches).map(\.id)
                
                if nameMatch || !matchedIDs.isEmpty {
                    kept.append(n)
                    visible[n.id] = matchedIDs
                }
            }
            
            visibleNames = kept
            visibleEntryIDsByNameID = visible
            
            namesByID = Dictionary(uniqueKeysWithValues: kept.map { ($0.id, $0) })
            entriesByNameID = Dictionary(uniqueKeysWithValues: kept.map { n in
                (n.id, Dictionary(uniqueKeysWithValues: n.content.map { ($0.id, $0) }))
            })
        }
        
        // MARK: Menu + Copy
        
        func makeMenu() -> NSMenu {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Copy Message", action: #selector(copyMessage(_:)), keyEquivalent: "c"))
            menu.addItem(NSMenuItem(title: "Copy All Info", action: #selector(copyAllInfo(_:)), keyEquivalent: ""))
            return menu
        }
        
        public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
            (outlineView?.selectedRow ?? -1) >= 0
        }
        
        @objc func copy(_ sender: Any?) { copyMessage(sender) }
        
        @objc func copyMessage(_ sender: Any?) { copyToClipboard(fullDetails: false) }
        
        @objc func copyAllInfo(_ sender: Any?) { copyToClipboard(fullDetails: true) }
        
        private func copyToClipboard(fullDetails: Bool) {
            guard let outlineView else { return }
            let rows = outlineView.selectedRowIndexes
            guard !rows.isEmpty else { return }
            
            var out: [String] = []
            out.reserveCapacity(rows.count)
            
            rows.forEach { row in
                guard let node = outlineView.item(atRow: row) as? LogNode else { return }
                
                switch node {
                case .category(let id):
                    if let name = namesByID[id]?.name { out.append("[\(name)]") }
                    
                case .entry(let nameID, let entryID):
                    guard let entry = entriesByNameID[nameID]?[entryID] else { return }
                    if fullDetails {
                        out.append("\(entry.date.formatted()) [\(entry.level.rawValue.uppercased())] \(entry.message)")
                    } else {
                        out.append(entry.message)
                    }
                }
            }
            
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(out.joined(separator: "\n"), forType: .string)
        }
        
        // MARK: DataSource
        
        public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            guard let node = item as? LogNode else { return visibleNames.count }
            switch node {
            case .category(let nameID):
                return visibleEntryIDsByNameID[nameID]?.count ?? 0
            case .entry:
                return 0
            }
        }
        
        public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            guard let node = item as? LogNode else { return LogNode.category(visibleNames[index].id) }
            
            if case .category(let nameID) = node,
               let ids = visibleEntryIDsByNameID[nameID],
               index < ids.count {
                return LogNode.entry(nameID, ids[index])
            }
            
            return LogNode.category(UUID())
        }
        
        public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            guard let node = item as? LogNode else { return false }
            if case .category = node { return true }
            return false
        }
        
        public func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
            if case .category = item as? LogNode { return true }
            return false
        }
        
        // MARK: Height
        
        public func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
            guard let node = item as? LogNode else { return OutlineLogView.baseRowHeight }
            
            switch node {
            case .category:
                return OutlineLogView.baseRowHeight
                
            case .entry(let nameID, let entryID):
                guard expandedEntryIDs.contains(entryID),
                      let entry = entriesByNameID[nameID]?[entryID] else {
                    return OutlineLogView.baseRowHeight
                }
                
                let colIndex = outlineView.column(withIdentifier: .init("message"))
                let width = colIndex >= 0 ? outlineView.tableColumns[colIndex].width : 400
                let availableWidth = width - 12
                
                let rect = (entry.message as NSString).boundingRect(
                    with: NSSize(width: availableWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: msgFont]
                )
                
                return max(OutlineLogView.baseRowHeight, rect.height + 12)
            }
        }
        
        // MARK: Cells
        
        public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let node = item as? LogNode else { return nil }
            
            if case .category(let nameID) = node {
                return groupCell(outlineView, title: namesByID[nameID]?.name ?? "Unknown")
            }
            
            guard let tableColumn,
                  case .entry(let nameID, let entryID) = node,
                  let entry = entriesByNameID[nameID]?[entryID] else { return nil }
            
            let key = tableColumn.identifier.rawValue
            let cell = makeCell(outlineView, id: "cell.\(key)")
            
            switch key {
            case "level":
                cell.textField?.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
                cell.textField?.stringValue = entry.level.rawValue.uppercased()
                cell.textField?.textColor = entry.level.color
                
            case "message":
                cell.textField?.font = msgFont
                cell.textField?.lineBreakMode = .byWordWrapping
                cell.textField?.maximumNumberOfLines = 0
                cell.textField?.textColor = .labelColor
                cell.textField?.stringValue = entry.message
                
            case "time":
                cell.textField?.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
                cell.textField?.textColor = .tertiaryLabelColor
                cell.textField?.stringValue = entry.date.formatted(date: .omitted, time: .standard)
                
            default:
                break
            }
            
            return cell
        }
        
        private func groupCell(_ outline: NSOutlineView, title: String) -> NSTableCellView {
            let cell = makeCell(outline, id: "GroupCell")
            cell.textField?.font = .systemFont(ofSize: 13, weight: .semibold)
            cell.textField?.textColor = .labelColor
            cell.textField?.stringValue = title
            return cell
        }
        
        private func makeCell(_ outline: NSOutlineView, id: String) -> NSTableCellView {
            let ident = NSUserInterfaceItemIdentifier(id)
            if let existing = outline.makeView(withIdentifier: ident, owner: self) as? NSTableCellView {
                return existing
            }
            
            let cell = NSTableCellView()
            cell.identifier = ident
            
            let tf = NSTextField(labelWithString: "")
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.isSelectable = false
            
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
        
        // MARK: Expand-on-select
        
        public func outlineViewSelectionDidChange(_ notification: Notification) {
            guard let outline = notification.object as? NSOutlineView else { return }
            let row = outline.selectedRow
            guard row >= 0, let node = outline.item(atRow: row) as? LogNode else { return }
            
            if case .entry(_, let entryID) = node {
                if expandedEntryIDs.contains(entryID) { expandedEntryIDs.remove(entryID) }
                else { expandedEntryIDs.insert(entryID) }
                
                outline.noteHeightOfRows(withIndexesChanged: IndexSet(integer: row))
            }
        }
    }
    
    // MARK: - Custom Outline View (Copy + Right Click selection)
    
    public class LogOutlineView: NSOutlineView {
        
        public override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
            true
        }
        
        @objc func copy(_ sender: Any?) {
            (delegate as? ComfyLogger.Coordinator)?.copy(sender)
        }
        
        public override func menu(for event: NSEvent) -> NSMenu? {
            let point = convert(event.locationInWindow, from: nil)
            let row = self.row(at: point)
            if row >= 0 && !selectedRowIndexes.contains(row) {
                selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            }
            return super.menu(for: event)
        }
    }
}
