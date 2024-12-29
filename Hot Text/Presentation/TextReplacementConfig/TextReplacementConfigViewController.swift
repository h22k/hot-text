//
//  TextReplacementConfigViewController.swift
//  Hot Text
//
//  Created by Halil Hakan Karabay on 25.12.2024.
//

import Cocoa
import Foundation
import Combine

class TextReplacementConfigViewController: NSViewController {
    private let textReplacementService: TextReplacementService
    private var selectedText: String?
    private var observers: [NSObjectProtocol] = []
    
    private lazy var contentStack: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 32
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var headerStack: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: "text.badge.plus", accessibilityDescription: "Add")
        iconView.contentTintColor = .controlAccentColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24)
        ])
        stack.addArrangedSubview(iconView)
        
        let titleLabel = NSTextField(labelWithString: "Add Text Replacement")
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .labelColor
        stack.addArrangedSubview(titleLabel)
        
        return stack
    }()
    
    private lazy var formStack: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var shortcutField: NSTextField = {
        let field = createTextField()
        field.placeholderString = "Type shortcut text..."
        return field
    }()
    
    private lazy var replacementField: NSTextField = {
        let field = createTextField()
        field.placeholderString = "Type replacement text..."
        field.cell?.usesSingleLineMode = true
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.cell?.lineBreakMode = .byTruncatingTail
        return field
    }()
    
    private lazy var addButton: NSButton = {
        let button = NSButton(title: "Add Replacement", target: self, action: #selector(addButtonClicked))
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.font = .systemFont(ofSize: NSFont.systemFontSize(for: .large), weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.wantsLayer = true
        button.layer?.cornerRadius = 8
        button.contentTintColor = .white
        
        return button
    }()
    
    init(textReplacementService: TextReplacementService, selectedText: String? = nil) {
        self.textReplacementService = textReplacementService
        self.selectedText = selectedText
        super.init(nibName: nil, bundle: nil)
        self.title = "Add Text Replacement"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let container = NSView()
        view = container
        
        // Add content stack
        container.addSubview(contentStack)
        
        // Add header
        contentStack.addArrangedSubview(headerStack)
        
        // Add form
        contentStack.addArrangedSubview(formStack)
        
        // Add fields with labels
        let shortcutStack = createFieldStack(label: "Shortcut:", field: shortcutField)
        formStack.addArrangedSubview(shortcutStack)
        
        let replacementStack = createFieldStack(label: "Replacement:", field: replacementField)
        formStack.addArrangedSubview(replacementStack)
        
        // Add button
        formStack.addArrangedSubview(addButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 600),
            
            contentStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 32),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -32),
            contentStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24),
            
            shortcutStack.widthAnchor.constraint(equalTo: formStack.widthAnchor),
            replacementStack.widthAnchor.constraint(equalTo: formStack.widthAnchor),
            
            shortcutField.widthAnchor.constraint(equalTo: shortcutStack.widthAnchor),
            replacementField.widthAnchor.constraint(equalTo: replacementStack.widthAnchor),
            
            addButton.widthAnchor.constraint(equalTo: formStack.widthAnchor, multiplier: 0.5)
        ])
        
        // Center the button
        formStack.setCustomSpacing(24, after: replacementStack)
        formStack.alignment = .centerX
        
        // Set initial values
        if let selectedText = selectedText {
            replacementField.stringValue = selectedText
            shortcutField.becomeFirstResponder()
        } else {
            replacementField.becomeFirstResponder()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set window properties
        if let window = view.window {
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = .windowBackgroundColor
            window.isMovableByWindowBackground = true
            window.hasShadow = true
            
            // Center window
            if let screen = window.screen {
                let screenRect = screen.visibleFrame
                let windowRect = window.frame
                let x = screenRect.midX - windowRect.width / 2
                let y = screenRect.midY - windowRect.height / 2
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
        }
        
        // Add visual feedback to fields
        [shortcutField, replacementField].forEach { field in
            let beginObserver = NotificationCenter.default.addObserver(
                forName: NSControl.textDidBeginEditingNotification,
                object: field,
                queue: .main
            ) { [weak field] _ in
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.15
                    field?.layer?.borderColor = NSColor.controlAccentColor.cgColor
                    field?.layer?.borderWidth = 2
                }
            }
            
            let endObserver = NotificationCenter.default.addObserver(
                forName: NSControl.textDidEndEditingNotification,
                object: field,
                queue: .main
            ) { [weak field] _ in
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.15
                    field?.layer?.borderColor = NSColor.separatorColor.cgColor
                    field?.layer?.borderWidth = 1
                }
            }
            
            observers.append(beginObserver)
            observers.append(endObserver)
        }
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    private func createTextField() -> NSTextField {
        let field = NSTextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.font = .systemFont(ofSize: 14)
        field.controlSize = .large
        field.focusRingType = .none
        field.wantsLayer = true
        field.layer?.cornerRadius = 8
        field.layer?.borderWidth = 1
        field.layer?.borderColor = NSColor.separatorColor.cgColor
        field.backgroundColor = .textBackgroundColor
        field.drawsBackground = true
        field.bezelStyle = .roundedBezel
        field.cell?.usesSingleLineMode = true
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.cell?.lineBreakMode = .byTruncatingTail
        
        NSLayoutConstraint.activate([
            field.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        return field
    }
    
    private func createFieldStack(label: String, field: NSTextField) -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let label = NSTextField(labelWithString: label)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabelColor
        
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(field)
        
        return stack
    }
    
    @objc private func addButtonClicked() {
        let shortcut = shortcutField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let replacement = replacementField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !shortcut.isEmpty else {
            shortcutField.becomeFirstResponder()
            showAlert(title: "Error", message: "Please enter a shortcut text")
            return
        }
        
        guard !replacement.isEmpty else {
            replacementField.becomeFirstResponder()
            showAlert(title: "Error", message: "Please enter a replacement text")
            return
        }
        
        do {
            try textReplacementService.addReplacement(shortcut, replacement: replacement)
            showAlert(title: "Success", message: "Text replacement added successfully") { [weak self] in
                self?.view.window?.close()
            }
        } catch {
            showAlert(title: "Error", message: "Failed to add replacement: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = title == "Error" ? .critical : .informational
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: view.window ?? NSApp.mainWindow ?? NSWindow()) { _ in
            completion?()
        }
    }
}
