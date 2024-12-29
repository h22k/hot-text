import Cocoa
import Carbon

final class ShortcutService {
    static let shared = ShortcutService()
    
    private var isRecording = false
    private var eventHandler: Any?
    private var shortcutHandler: (() -> Void)?
    
    private var currentKeyCode: UInt16 = 0
    private var currentModifierFlags: NSEvent.ModifierFlags = []
    private var triggerKeyCode: UInt16 = 0x30  // Default to Tab key
    
    private init() {
        loadSavedShortcut()
        loadTriggerKey()
    }
    
    private func loadSavedShortcut() {
        if let shortcut = UserDefaults.standard.dictionary(forKey: "GlobalShortcut") {
            let keyCode = shortcut["keyCode"] as? UInt16 ?? 0
            let modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(shortcut["modifierFlags"] as? UInt64 ?? 0))
            
            if keyCode != 0 || !modifierFlags.isEmpty {
                registerGlobalShortcut(keyCode: keyCode, modifierFlags: modifierFlags)
                print("Loaded saved shortcut - KeyCode: \(keyCode), Modifiers: \(modifierFlags)")
            }
        }
    }
    
    private func loadTriggerKey() {
        let savedKey = UserDefaults.standard.integer(forKey: "TriggerKey")
        print("Loading trigger key from defaults: \(savedKey)")
        triggerKeyCode = savedKey == 0 ? 0x30 : UInt16(savedKey)  // Default to Tab key if not set
        print("Set trigger key to: \(triggerKeyCode) (\(keyCodeToString(triggerKeyCode)))")
        
        if savedKey == 0 {
            UserDefaults.standard.set(Int(triggerKeyCode), forKey: "TriggerKey")
        }
    }
    
    func getCurrentShortcut() -> (keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags)? {
        if let shortcut = UserDefaults.standard.dictionary(forKey: "GlobalShortcut") {
            let keyCode = shortcut["keyCode"] as? UInt16 ?? 0
            let modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(shortcut["modifierFlags"] as? UInt64 ?? 0))
            
            if keyCode != 0 || !modifierFlags.isEmpty {
                return (keyCode, modifierFlags)
            }
        }
        return nil
    }
    
    func setupDefaultShortcut() {
        if getCurrentShortcut() == nil {
            // Default shortcut: Shift + Option + W
            let defaultKeyCode: UInt16 = 0x0D // W key
            let defaultModifiers: NSEvent.ModifierFlags = [.shift, .option]
            
            updateShortcut(keyCode: defaultKeyCode, modifierFlags: defaultModifiers)
        }
    }
    
    func updateShortcut(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) {
        unregisterGlobalShortcut()
        
        let shortcut: [String: Any] = [
            "keyCode": keyCode,
            "modifierFlags": modifierFlags.rawValue
        ]
        UserDefaults.standard.set(shortcut, forKey: "GlobalShortcut")
        
        registerGlobalShortcut(keyCode: keyCode, modifierFlags: modifierFlags)
        print("Updated shortcut - KeyCode: \(keyCode), Modifiers: \(modifierFlags)")
    }
    
    func registerGlobalShortcut(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags, handler: @escaping () -> Void) {
        self.shortcutHandler = handler
        registerGlobalShortcut(keyCode: keyCode, modifierFlags: modifierFlags)
    }
    
    private func registerGlobalShortcut(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) {
        currentKeyCode = keyCode
        currentModifierFlags = modifierFlags
        
        unregisterGlobalShortcut()  // Unregister existing handler first
        
        // Use both local and global monitors to catch all key events
        let localHandler = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
        
        let globalHandler = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        // Store both handlers
        eventHandler = [localHandler, globalHandler]
    }
    
    func unregisterGlobalShortcut() {
        if let handlers = eventHandler as? [Any] {
            handlers.forEach { NSEvent.removeMonitor($0) }
        }
        eventHandler = nil
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard !isRecording else { return }
        
        let pressedKeyCode = event.keyCode
        let pressedModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        if pressedKeyCode == currentKeyCode && pressedModifiers == currentModifierFlags {
            DispatchQueue.main.async { [weak self] in
                self?.shortcutHandler?()
            }
        }
    }
    
    func setRecording(_ recording: Bool) {
        isRecording = recording
    }
    
    func isShortcutReserved(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) -> Bool {
        // List of reserved shortcuts
        let reservedShortcuts: [(keyCode: UInt16, modifiers: NSEvent.ModifierFlags)] = [
            (0x7B, [.command]), // Cmd + Left Arrow
            (0x7C, [.command]), // Cmd + Right Arrow
            (0x7D, [.command]), // Cmd + Down Arrow
            (0x7E, [.command]), // Cmd + Up Arrow
            (0x33, [.command]), // Cmd + Delete
            (0x75, [.command]), // Cmd + Forward Delete
            (0x24, [.command]), // Cmd + Return
            (0x4C, [.command]), // Cmd + Enter
            (0x35, [.command]), // Cmd + Escape
            (0x30, [.command]), // Cmd + Tab
            (0x31, [.command]), // Cmd + Space
            (0x0C, [.command]), // Cmd + Q
            (0x0D, [.command]), // Cmd + W
            (0x0F, [.command]), // Cmd + R
            (0x21, [.command]), // Cmd + 4 (Screenshot)
            (0x1E, [.command]), // Cmd + 1
            (0x1F, [.command]), // Cmd + 2
            (0x20, [.command]), // Cmd + 3
            (0x21, [.command]), // Cmd + 4
            (0x23, [.command]), // Cmd + 5
            (0x22, [.command]), // Cmd + 6
            (0x26, [.command]), // Cmd + 7
            (0x28, [.command]), // Cmd + 8
            (0x25, [.command]), // Cmd + 9
            (0x29, [.command]), // Cmd + 0
        ]
        
        return reservedShortcuts.contains { shortcut in
            shortcut.keyCode == keyCode && shortcut.modifiers == modifierFlags
        }
    }
    
    func shortcutDescription(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) -> String {
        var description = ""
        
        if modifierFlags.contains(.control) {
            description += "⌃"
        }
        if modifierFlags.contains(.option) {
            description += "⌥"
        }
        if modifierFlags.contains(.shift) {
            description += "⇧"
        }
        if modifierFlags.contains(.command) {
            description += "⌘"
        }
        
        let keyCharacter = keyCodeToString(keyCode)
        description += keyCharacter
        
        return description
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String {
        // First check for special keys
        switch keyCode {
        // Letters
        case 0x00: return "A"
        case 0x0B: return "B"
        case 0x08: return "C"
        case 0x02: return "D"
        case 0x0E: return "E"
        case 0x03: return "F"
        case 0x05: return "G"
        case 0x04: return "H"
        case 0x22: return "I"
        case 0x26: return "J"
        case 0x28: return "K"
        case 0x25: return "L"
        case 0x2E: return "M"
        case 0x2D: return "N"
        case 0x1F: return "O"
        case 0x23: return "P"
        case 0x0C: return "Q"
        case 0x0F: return "R"
        case 0x01: return "S"
        case 0x11: return "T"
        case 0x20: return "U"
        case 0x09: return "V"
        case 0x0D: return "W"
        case 0x07: return "X"
        case 0x10: return "Y"
        case 0x06: return "Z"
        
        // Numbers
        case 0x12: return "1"
        case 0x13: return "2"
        case 0x14: return "3"
        case 0x15: return "4"
        case 0x17: return "5"
        case 0x16: return "6"
        case 0x1A: return "7"
        case 0x1C: return "8"
        case 0x19: return "9"
        case 0x1D: return "0"
        
        // Special Characters
        case 0x27: return "-"
        case 0x2A: return "⌫"  // Backslash
        case 0x2B: return "="
        case 0x2C: return "["
        case 0x2F: return "]"
        case 0x32: return "`"
        case 0x41: return ","
        case 0x43: return ";"
        case 0x44: return "/"
        case 0x47: return "."
        case 0x4E: return "-"
        case 0x4F: return "="
        case 0x50: return "/"
        case 0x51: return "*"
        case 0x52: return "+"
        
        // Function Keys
        case 0x7A: return "F1"
        case 0x78: return "F2"
        case 0x63: return "F3"
        case 0x76: return "F4"
        case 0x60: return "F5"
        case 0x61: return "F6"
        case 0x62: return "F7"
        case 0x64: return "F8"
        case 0x65: return "F9"
        case 0x6D: return "F10"
        case 0x67: return "F11"
        case 0x6F: return "F12"
        case 0x69: return "F13"
        case 0x6B: return "F14"
        case 0x71: return "F15"
        
        // Special Keys
        case 0x24: return "⏎"    // Return
        case 0x4C: return "⌤"    // Enter
        case 0x35: return "⎋"    // Escape
        case 0x33: return "⌫"    // Delete/Backspace
        case 0x75: return "⌦"    // Forward Delete
        case 0x30: return "⇥"    // Tab
        case 0x31: return "␣"    // Space
        case 0x7B: return "←"    // Left Arrow
        case 0x7C: return "→"    // Right Arrow
        case 0x7D: return "↓"    // Down Arrow
        case 0x7E: return "↑"    // Up Arrow
        
        // Modifier Keys
        case 0x38: return "⇧"    // Left Shift
        case 0x3C: return "⇧"    // Right Shift
        case 0x3B: return "⌃"    // Left Control
        case 0x3E: return "⌃"    // Right Control
        case 0x3A: return "⌥"    // Left Option
        case 0x3D: return "⌥"    // Right Option
        case 0x37: return "⌘"    // Left Command
        case 0x36: return "⌘"    // Right Command
        case 0x72: return "⇪"    // Caps Lock
        
        // Navigation Keys
        case 0x73: return "⇱"    // Home
        case 0x77: return "⇲"    // End
        case 0x74: return "⇞"    // Page Up
        case 0x79: return "⇟"    // Page Down
        
        default: return "?"
        }
    }
    
    func getCurrentTriggerKey() -> UInt16 {
        return triggerKeyCode
    }
    
    func updateTriggerKey(_ keyCode: UInt16) {
        print("Updating trigger key to: \(keyCode) (\(keyCodeToString(keyCode)))")
        triggerKeyCode = keyCode
        UserDefaults.standard.set(Int(keyCode), forKey: "TriggerKey")
        NotificationCenter.default.post(name: .triggerKeyDidUpdate, object: nil)
    }
    
    func isTriggerKey(_ keyCode: UInt16) -> Bool {
        print("Checking trigger key: \(keyCode) vs \(triggerKeyCode)")
        return keyCode == triggerKeyCode
    }
} 
