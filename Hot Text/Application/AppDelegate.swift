import Cocoa
import SwiftUI
import ServiceManagement
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let keyboardService = KeyboardService.shared
    private let shortcutService = ShortcutService.shared
    private let textReplacementService = TextReplacementService.shared
    private let windowManager = WindowManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set app to accessory mode (menu bar only)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize services
        shortcutService.setupDefaultShortcut()
        
        // Register global shortcut handler
        if let shortcut = shortcutService.getCurrentShortcut() {
            shortcutService.registerGlobalShortcut(keyCode: shortcut.keyCode, modifierFlags: shortcut.modifierFlags) { [weak self] in
                self?.handleGlobalShortcut()
            }
        }
        
        // Setup app
        setupLoginItem()
        setupStatusItem()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup services
        shortcutService.unregisterGlobalShortcut()
        
        // Remove status item
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
    
    private func setupLoginItem() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("Failed to register login item:", error)
        }
    }
    
    private func setupStatusItem() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Configure button
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "Hot Text")
        }
        
        // Create menu
        let menu = NSMenu()
        
        // Add Text Replacement
        menu.addItem(withTitle: "Add Text Replacement", action: #selector(showTextReplacementConfig), keyEquivalent: "n")
        
        // Show All Replacements
        menu.addItem(withTitle: "Show All Replacements", action: #selector(showAllReplacements), keyEquivalent: "l")
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        menu.addItem(withTitle: "Settings", action: #selector(showSettings), keyEquivalent: ",")
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        
        // Set menu items target
        for item in menu.items {
            item.target = self
        }
        
        // Set menu
        statusItem?.menu = menu
    }
    
    @objc func showTextReplacementConfig() {
        NSApp.activate(ignoringOtherApps: true)
        let selectedText = NSPasteboard.general.string(forType: .string)
        windowManager.showConfigWindow(withSelectedText: selectedText)
    }
    
    @objc func showAllReplacements() {
        NSApp.activate(ignoringOtherApps: true)
        let replacements = textReplacementService.getAllReplacements()
        windowManager.showListWindow(with: replacements)
    }
    
    @objc func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        windowManager.showSettingsWindow()
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func handleGlobalShortcut() {
        // First try to get selected text from active application
        let selectedText = getSelectedText()
        
        // Show config window with selected text
        windowManager.showConfigWindow(withSelectedText: selectedText)
    }
    
    private func getSelectedText() -> String? {
        // Try to get selected text from active application
        if let activeApp = NSWorkspace.shared.frontmostApplication {
            let element = AXUIElementCreateApplication(activeApp.processIdentifier)
            if let selectedText = try? getSelectedTextFromElement(element) {
                return selectedText
            }
        }
        
        // Fallback to clipboard if no text is selected
        return NSPasteboard.general.string(forType: .string)
    }
    
    private func getSelectedTextFromElement(_ element: AXUIElement) throws -> String? {
        var selectedTextValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedTextValue)
        
        if result == .success, 
           let value = selectedTextValue,
           let text = value as? String {
            return text
        }
        
        // If no direct selection, try to get focused element and its selection
        var focusedElement: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
           let focused = focusedElement,
           CFGetTypeID(focused) == AXUIElementGetTypeID() {
            let focusedUIElement = focused as! AXUIElement
            var selectedText: CFTypeRef?
            if AXUIElementCopyAttributeValue(focusedUIElement, kAXSelectedTextAttribute as CFString, &selectedText) == .success,
               let value = selectedText {
                return value as? String
            }
        }
        
        return nil
    }
}
