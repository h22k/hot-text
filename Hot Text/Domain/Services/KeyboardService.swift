import Cocoa
import Foundation

final class KeyboardService {
    static let shared = KeyboardService()
    
    private var currentBuffer: String = ""
    private var isTracking = false
    private var monitorEvents: [Any] = []
    private let replacementService: TextReplacementService
    private let shortcutService: ShortcutService
    
    private init() {
        print("🔄 Initializing KeyboardService")
        self.replacementService = TextReplacementService.shared
        self.shortcutService = ShortcutService.shared
        setupKeyboardMonitoring()
    }
    
    private func setupKeyboardMonitoring() {
        print("⌨️ Setting up keyboard monitoring...")
        
        // Setup keyboard monitoring only if we have permission
        if AXIsProcessTrusted() {
            print("✅ Accessibility permissions granted, setting up keyboard monitors")
            
            // Monitor for global keyDown events
            let keyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                print("🎹 Global KeyDown event received - KeyCode: \(event.keyCode)")
                self?.handleKeyPress(event)
            }
            
            if let monitor = keyDownMonitor {
                monitorEvents.append(monitor)
                print("✅ Global KeyDown monitor added")
            } else {
                print("❌ Failed to create global monitor")
            }
            
            // Monitor for local keyDown events
            let localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                print("🎹 Local KeyDown event received - KeyCode: \(event.keyCode)")
                self?.handleKeyPress(event)
                return event
            }
            
            if let monitor = localKeyDownMonitor {
                monitorEvents.append(monitor)
                print("✅ Local KeyDown monitor added")
            } else {
                print("❌ Failed to create local monitor")
            }
            
            print("✅ Keyboard monitoring setup complete with \(monitorEvents.count) monitors")
        } else {
            print("❌ Accessibility permissions NOT granted - keyboard monitoring will not work")
        }
    }
    
    deinit {
        // Clean up monitors
        monitorEvents.forEach { NSEvent.removeMonitor($0) }
        print("🧹 Cleaned up keyboard monitors")
    }
    
    private func handleKeyPress(_ event: NSEvent) {
        guard let characters = event.characters else {
            print("⚠️ No characters in event")
            return
        }
        
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        print("🔑 Key Event - Char: \"\(characters)\", KeyCode: \(event.keyCode), Modifiers: \(modifiers)")
        print("📊 Current State - isTracking: \(isTracking), Buffer: \"\(currentBuffer)\"")
        
        // Check for space or trigger key to stop tracking if we're not in a valid shortcut
        if isTracking && (event.keyCode == Constants.Keyboard.spaceKeyCode || shortcutService.isTriggerKey(event.keyCode)) {
            print("🔍 Checking replacement for buffer: \"\(currentBuffer)\"")
            if !replacementService.hasReplacement(for: currentBuffer) {
                print("❌ Invalid shortcut detected - Buffer: \"\(currentBuffer)\"")
                isTracking = false
                currentBuffer = ""
            } else {
                print("✨ Valid replacement found for: \"\(currentBuffer)\"")
            }
        }
        
        // Check for "/" to start tracking
        if characters == Constants.Keyboard.triggerCharacter {
            isTracking = true
            currentBuffer = Constants.Keyboard.triggerCharacter
            print("🎯 Started tracking with initial buffer: \"\(currentBuffer)\"")
            return
        }
        
        // Only process input if we're tracking (after seeing a /)
        if isTracking {
            if shortcutService.isTriggerKey(event.keyCode) {
                print("⚡️ Trigger key pressed - Current buffer: \"\(currentBuffer)\"")
                print("🔍 Searching for replacement - Key: \"\(currentBuffer)\"")
                
                let allReplacements = replacementService.getAllReplacements()
                print("📚 Available replacements: \(allReplacements)")
                print("🎯 Looking for key: \"\(currentBuffer)\" in replacements")
                
                if replacementService.performReplacement(for: currentBuffer) {
                    print("✅ Replacement performed successfully")
                } else {
                    print("❌ No replacement found for: \"\(currentBuffer)\"")
                }
                
                isTracking = false
                currentBuffer = ""
                print("🔄 Reset buffer and tracking state")
            } else if event.keyCode == Constants.Keyboard.backspaceKeyCode {
                if !currentBuffer.isEmpty {
                    currentBuffer.removeLast()
                    print("⌫ Backspace - New buffer: \"\(currentBuffer)\"")
                    if currentBuffer.isEmpty {
                        isTracking = false
                        print("📴 Buffer empty - Stopped tracking")
                    }
                }
            } else {
                // Append character to buffer if it's a valid input
                if characters.rangeOfCharacter(from: .whitespacesAndNewlines) == nil {
                    currentBuffer += characters
                    print("📝 Added to buffer: \"\(currentBuffer)\"")
                } else {
                    print("⚠️ Skipping whitespace character")
                }
            }
        }
    }
} 
