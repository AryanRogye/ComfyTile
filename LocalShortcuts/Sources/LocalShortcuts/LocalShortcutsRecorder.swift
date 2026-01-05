//
//  LocalShortcutsRecorder.swift
//  LocalShortcuts
//
//  Created by Aryan Rogye on 12/4/25.
//

import AppKit
import SwiftUI
import Carbon.HIToolbox

extension LocalShortcuts {
    public struct LocalShortcutsRecorder: NSViewRepresentable {
        
        let name : Name

        public init(for name: Name) {
            self.name = name
        }
        
        
        public func makeNSView(context: Context) -> LocalShortcutRecorderContainer {
            return LocalShortcutRecorderContainer(for: name)
        }
        
        public func updateNSView(_ nsView: LocalShortcuts.LocalShortcutRecorderContainer, context: Context) {
            
        }
    }
    
    @MainActor
    public final class LocalShortcutRecorderContainer: NSView {
        private let searchField: LocalShortcutRecorderSearch
        private let doneButton: NSButton
        private let stackView: NSStackView
        
        public init(for name: LocalShortcuts.Name) {
            self.searchField = LocalShortcutRecorderSearch(for: name)
            self.doneButton = NSButton(title: "Done", target: nil, action: nil)
            self.stackView = NSStackView()
            super.init(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            
            doneButton.bezelStyle = .rounded
            doneButton.setButtonType(.momentaryPushIn)
            doneButton.target = self
            doneButton.action = #selector(stopRecording)
            doneButton.isEnabled = false
            doneButton.alphaValue = 0.5
            
            stackView.orientation = .horizontal
            stackView.alignment = .centerY
            stackView.spacing = 8
            stackView.addArrangedSubview(searchField)
            stackView.addArrangedSubview(doneButton)
            
            addSubview(stackView)
            stackView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                searchField.widthAnchor.constraint(greaterThanOrEqualToConstant: searchField.minimumWidth)
            ])
            
            searchField.onRecordingChange = { [weak self] isRecording in
                self?.updateButton(isRecording: isRecording)
            }
        }
        
        @available(*, unavailable)
        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func updateButton(isRecording: Bool) {
            doneButton.isEnabled = isRecording
            doneButton.alphaValue = isRecording ? 1.0 : 0.5
        }
        
        @objc private func stopRecording() {
            searchField.finishRecording()
        }
    }
    
    @MainActor
    public final class LocalShortcutRecorderSearch: NSSearchField, NSSearchFieldDelegate {
        
        fileprivate let minimumWidth = 130.0
        private(set) var isRecording = false {
            didSet { onRecordingChange?(isRecording) }
        }
        
        var onRecordingChange: ((Bool) -> Void)?
        
        private let name: LocalShortcuts.Name
        private var eventMonitor: Any?
        
        public required init(
            for name: LocalShortcuts.Name
        ) {
            self.name = name
            
            super.init(frame: NSRect(x: 0, y: 0, width: minimumWidth, height: 24))
            
            delegate = self
            placeholderString = "Press shortcut"
            alignment = .center
            (cell as? NSSearchFieldCell)?.searchButtonCell = nil
            
            wantsLayer = true
            setContentHuggingPriority(.defaultHigh, for: .vertical)
            setContentHuggingPriority(.defaultHigh, for: .horizontal)
            
            updateStringValue()
        }
        
        @available(*, unavailable)
        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func updateStringValue() {
            if let shortcut = LocalShortcuts.Name.shortcuts[name] {
                stringValue = shortcut.displayValue()
            } else {
                stringValue = ""
            }
        }
        
        // MARK: - Recording
        
        override public func becomeFirstResponder() -> Bool {
            let ok = super.becomeFirstResponder()
            guard ok else { return false }
            
            placeholderString = "Press shortcut…"
            startRecording()
            return true
        }
        
        override public func resignFirstResponder() -> Bool {
            stopRecording()
            return super.resignFirstResponder()
        }
        
        private func startRecording() {
            guard eventMonitor == nil else { return }
            isRecording = true
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                self?.handleKeyEvent(event)
                return nil
            }
        }
        
        private func stopRecording() {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
            isRecording = false
            placeholderString = "Press shortcut"
        }
        
        func finishRecording() {
            stopRecording()
            window?.makeFirstResponder(nil)
            updateStringValue()
        }
        
        private func handleKeyEvent(_ event: NSEvent) {
            // Escape cancels
            if event.keyCode == kVK_Escape {
                window?.makeFirstResponder(nil)
                return
            }
            
            // Build your LocalShortcuts.Shortcut from the NSEvent
            guard let shortcut = LocalShortcuts.Shortcut.from(event: event) else {
                NSSound.beep()
                updateStringValue()
                return
            }
            
            // Store it in your bindings
            LocalShortcuts.Name.shortcuts[name] = shortcut
            
            // Update UI
            stringValue = shortcut.displayValue()
            window?.makeFirstResponder(nil)
        }
    }}
