import Cocoa

final class KeyboardService {
    static let shared = KeyboardService()
    
    private var currentBuffer: String = ""
    private var isTracking = false
    private var monitorEvent: Any?
    private let replacementService = TextReplacementService.shared
    private let shortcutService = ShortcutService.shared
    
    private init() {
        setupKeyboardMonitoring()
    }
    
    private func setupKeyboardMonitoring() {
        // Setup keyboard monitoring only if we have permission
        if AXIsProcessTrusted() {
            monitorEvent = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                self?.handleKeyPress(event)
            }
        }
    }
    
    private func handleKeyPress(_ event: NSEvent) {
        guard let characters = event.characters else { return }
        
        print("Key pressed:", characters, "keyCode:", event.keyCode)
        
        // Check for space or trigger key to stop tracking if we're not in a valid shortcut
        if isTracking && (event.keyCode == 49 || shortcutService.isTriggerKey(event.keyCode)) {
            if !replacementService.hasReplacement(for: currentBuffer) {
                print("Invalid shortcut, stopping tracking. Buffer was:", currentBuffer)
                isTracking = false
                currentBuffer = ""
            }
        }
        
        // Check for "/" to start tracking
        if characters == "/" {
            isTracking = true
            currentBuffer = "/"
            print("Started tracking with buffer:", currentBuffer)
            return
        }
        
        // Only process input if we're tracking (after seeing a /)
        if isTracking {
            if shortcutService.isTriggerKey(event.keyCode) {
                print("Trigger key pressed. Current buffer:", currentBuffer)
                
                print("Searching for key:", currentBuffer)
                print("Available replacements:", replacementService.getAllReplacements())
                
                if replacementService.performReplacement(for: currentBuffer) {
                    print("Replacement performed")
                } else {
                    print("No replacement found for:", currentBuffer)
                }
                
                isTracking = false
                currentBuffer = ""
                print("Reset buffer and tracking")
            } else if event.keyCode == 51 { // Backspace
                if !currentBuffer.isEmpty {
                    currentBuffer.removeLast()
                    print("Backspace pressed, new buffer:", currentBuffer)
                    if currentBuffer.isEmpty {
                        isTracking = false
                        print("Buffer empty, stopped tracking")
                    }
                }
            } else {
                // Append character to buffer if it's a valid input
                if characters.rangeOfCharacter(from: .whitespacesAndNewlines) == nil {
                    currentBuffer += characters
                    print("Added to buffer:", currentBuffer)
                }
            }
        }
    }
} 