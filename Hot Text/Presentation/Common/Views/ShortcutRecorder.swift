import Cocoa

class ShortcutRecorder: NSView {
    weak var delegate: ShortcutRecorderDelegate?
    var requiresModifiers = true  // New property to control modifier requirement
    
    private var isRecording = false {
        didSet {
            updateDisplay()
            ShortcutService.shared.setRecording(isRecording)
        }
    }
    
    private var currentKeyCode: UInt16 = 0
    private var currentModifiers: NSEvent.ModifierFlags = []
    
    private let textField: NSTextField = {
        let field = NSTextField()
        field.isEditable = false
        field.isBordered = true
        field.backgroundColor = .textBackgroundColor
        field.alignment = .center
        field.placeholderString = "Click to record"
        return field
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 4
        
        textField.frame = bounds
        addSubview(textField)
        
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        addGestureRecognizer(clickGesture)
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    @objc private func handleClick() {
        if !isRecording {
            window?.makeFirstResponder(self)
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        currentKeyCode = 0
        currentModifiers = []
    }
    
    private func stopRecording() {
        isRecording = false
        window?.makeFirstResponder(nil)
    }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        // Escape cancels recording
        if event.keyCode == 53 {
            currentKeyCode = 0
            currentModifiers = []
            stopRecording()
            return
        }
        
        // Get the key code and modifiers
        currentKeyCode = event.keyCode
        currentModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // Print debug info
        print("Key down - KeyCode: \(currentKeyCode), Characters: \(event.characters ?? ""), ModifierFlags: \(currentModifiers)")
        
        // Check if the shortcut is reserved
        if requiresModifiers && ShortcutService.shared.isShortcutReserved(keyCode: currentKeyCode, modifierFlags: currentModifiers) {
            AlertPresenter.shared.showAlert(
                title: "Reserved Shortcut",
                message: "This shortcut is reserved by macOS. Please choose a different combination.",
                style: .warning
            )
            return
        }
        
        // For trigger key, accept any key including modifiers
        if !requiresModifiers {
            // Special handling for function keys and other special keys
            let specialKeys: Set<UInt16> = [
                0x24, // Return
                0x4C, // Enter
                0x35, // Escape
                0x33, // Delete
                0x75, // Forward Delete
                0x30, // Tab
                0x31, // Space
                0x7B, // Left Arrow
                0x7C, // Right Arrow
                0x7D, // Down Arrow
                0x7E, // Up Arrow
                0x72, // Caps Lock
                0x73, // Home
                0x77, // End
                0x74, // Page Up
                0x79, // Page Down
                0x71, // Clear
                // Function keys
                0x7A, // F1
                0x78, // F2
                0x63, // F3
                0x76, // F4
                0x60, // F5
                0x61, // F6
                0x62, // F7
                0x64, // F8
                0x65, // F9
                0x6D, // F10
                0x67, // F11
                0x6F, // F12
                0x69, // F13
                0x6B, // F14
                0x71, // F15
            ]
            
            // If it's a special key or a regular key press, record it
            if specialKeys.contains(currentKeyCode) {
                delegate?.shortcutRecorder(self, didChangeKeyCode: currentKeyCode, modifierFlags: [])
                stopRecording()
            } else if let char = event.characters?.first, char.isASCII {
                // For regular keys, use the key code directly
                delegate?.shortcutRecorder(self, didChangeKeyCode: currentKeyCode, modifierFlags: [])
                stopRecording()
            }
            return
        }
        
        // For global shortcut, require at least one modifier
        if !currentModifiers.isEmpty {
            delegate?.shortcutRecorder(self, didChangeKeyCode: currentKeyCode, modifierFlags: currentModifiers)
            stopRecording()
        }
    }
    
    override func flagsChanged(with event: NSEvent) {
        if isRecording {
            currentModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            // For trigger key, allow recording modifier keys directly
            if !requiresModifiers {
                let keyCode = event.keyCode
                let modifierKeys: Set<UInt16> = [
                    0x38, // Left Shift
                    0x3C, // Right Shift
                    0x3B, // Left Control
                    0x3E, // Right Control
                    0x3A, // Left Option
                    0x3D, // Right Option
                    0x37, // Left Command
                    0x36, // Right Command
                    0x72  // Caps Lock
                ]
                
                if modifierKeys.contains(keyCode) {
                    currentKeyCode = keyCode  // Set the current key code before stopping
                    delegate?.shortcutRecorder(self, didChangeKeyCode: keyCode, modifierFlags: [])
                    stopRecording()
                }
            }
            
            updateDisplay()
        }
    }
    
    private func updateDisplay() {
        if isRecording {
            textField.stringValue = "Recording..."
            textField.textColor = .systemBlue
        } else {
            if currentKeyCode == 0 && currentModifiers.isEmpty {
                textField.stringValue = "Click to record"
                textField.textColor = .textColor
            } else {
                // For global shortcuts, show modifiers. For trigger keys, don't show modifiers
                textField.stringValue = ShortcutService.shared.shortcutDescription(
                    keyCode: currentKeyCode,
                    modifierFlags: requiresModifiers ? currentModifiers : []
                )
                textField.textColor = .textColor
            }
        }
    }
    
    func setShortcut(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) {
        currentKeyCode = keyCode
        currentModifiers = requiresModifiers ? modifierFlags : []  // Keep modifiers for global shortcuts
        updateDisplay()
    }
} 