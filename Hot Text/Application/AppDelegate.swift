import Cocoa
import SwiftUI
import ServiceManagement
import ApplicationServices
import IOKit.hid
import CoreGraphics

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let keyboardService = KeyboardService.shared
    private let shortcutService = ShortcutService.shared
    private let textReplacementService = TextReplacementService.shared
    private let windowManager = WindowManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set app to accessory mode (menu bar only)
        NSApp.setActivationPolicy(.accessory)
        
        // Check and request permissions
        checkAndRequestPermissions()
        
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
    
    private func checkAndRequestPermissions() {
        print("🔍 Starting permission checks...")
        var missingPermissions: [String] = []
        
        // Force prompt for Accessibility permissions if needed
        let axOptions = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(axOptions as CFDictionary)
        
        // Check Accessibility permissions
        let axEnabled = AXIsProcessTrusted()
        print("🔐 Accessibility Status: \(axEnabled ? "Enabled" : "Disabled")")
        if !axEnabled {
            missingPermissions.append("Accessibility")
        }
        
        // Check Input Monitoring permissions
        let inputMonitoringEnabled = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        print("🔐 Input Monitoring Status: \(inputMonitoringEnabled ? "Enabled" : "Disabled")")
        if !inputMonitoringEnabled {
            missingPermissions.append("Input Monitoring")
        }
        
        // Check Apple Events permissions with prompt
        let options = NSDictionary(dictionary: [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true])
        let appleEventsEnabled = AXIsProcessTrustedWithOptions(options)
        print("🔐 Apple Events Status: \(appleEventsEnabled ? "Enabled" : "Disabled")")
        if !appleEventsEnabled {
            missingPermissions.append("Apple Events")
        }
        
        // Print current process information
        if let bundleID = Bundle.main.bundleIdentifier {
            print("📦 Bundle ID: \(bundleID)")
        }
        print("📍 Process Path: \(Bundle.main.bundlePath)")
        print("🔑 Process ID: \(ProcessInfo.processInfo.processIdentifier)")
        
        // Try to create a test event monitor
        let testMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { _ in }
        if testMonitor != nil {
            print("✅ Test event monitor created successfully")
            NSEvent.removeMonitor(testMonitor!)
        } else {
            print("⚠️ Failed to create test event monitor")
        }
        
        if !missingPermissions.isEmpty {
            print("❌ Missing permissions: \(missingPermissions.joined(separator: ", "))")
            
            DispatchQueue.main.async { [weak self] in
                self?.showPermissionsAlert(missingPermissions: missingPermissions)
            }
        } else {
            print("✅ All required permissions are granted")
            
            // Double check if we can actually monitor events
            let eventMask: NSEvent.EventTypeMask = [.keyDown]
            let monitorResult = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { _ in }
            if monitorResult != nil {
                print("✅ Successfully created event monitor")
                NSEvent.removeMonitor(monitorResult!)
            } else {
                print("⚠️ Failed to create event monitor despite having permissions")
                DispatchQueue.main.async { [weak self] in
                    self?.showPermissionsAlert(missingPermissions: ["Event Monitoring"])
                }
            }
        }
    }
    
    private func showPermissionsAlert(missingPermissions: [String]) {
        let alert = NSAlert()
        alert.messageText = "Additional Permissions Required"
        alert.informativeText = """
            Hot Text needs the following permissions to work properly:
            
            \(missingPermissions.map { "• \($0)" }.joined(separator: "\n"))
            
            Please enable these permissions in System Settings > Privacy & Security.
            
            After enabling the permissions, please quit and relaunch Hot Text.
            
            Note: If you've already granted these permissions, try removing and re-adding them.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Quit Hot Text")
        alert.addButton(withTitle: "Later")
        
        NSApp.activate(ignoringOtherApps: true)
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings
            let prefpaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
            NSWorkspace.shared.open(prefpaneURL)
        } else if response == .alertSecondButtonReturn {
            // Quit app
            NSApplication.shared.terminate(nil)
        }
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
        windowManager.showConfigWindow()
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
        windowManager.showConfigWindow()
    }
}

