import Cocoa

final class KeyboardEventSimulator {
    static let shared = KeyboardEventSimulator()
    
    private init() {}
    
    func simulateBackspace() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyBackspace = CGEvent(keyboardEventSource: source, virtualKey: Constants.Keyboard.backspaceKeyCode, keyDown: true)
        let keyBackspaceUp = CGEvent(keyboardEventSource: source, virtualKey: Constants.Keyboard.backspaceKeyCode, keyDown: false)
        
        keyBackspace?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: Constants.Storage.keyDelayInterval)
        keyBackspaceUp?.post(tap: .cghidEventTap)
    }
    
    func simulateKeyPress(_ character: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        var utf16Array = Array(character.utf16)
        
        utf16Array.withUnsafeBufferPointer { buffer in
            let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
            event?.flags = .maskNonCoalesced
            event?.keyboardSetUnicodeString(stringLength: character.utf16.count, unicodeString: buffer.baseAddress)
            event?.post(tap: .cghidEventTap)
            
            Thread.sleep(forTimeInterval: Constants.Storage.keyDelayInterval)
            
            let eventUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            eventUp?.flags = .maskNonCoalesced
            eventUp?.keyboardSetUnicodeString(stringLength: character.utf16.count, unicodeString: buffer.baseAddress)
            eventUp?.post(tap: .cghidEventTap)
        }
    }
    
    func deleteCharacters(count: Int) {
        for _ in 0..<count {
            simulateBackspace()
            Thread.sleep(forTimeInterval: Constants.Storage.keyDelayInterval)
        }
    }
    
    func insertText(_ text: String) {
        Thread.sleep(forTimeInterval: Constants.Storage.replacementDelayInterval)
        for char in text {
            simulateKeyPress(String(char))
            Thread.sleep(forTimeInterval: Constants.Storage.keyDelayInterval)
        }
    }
} 