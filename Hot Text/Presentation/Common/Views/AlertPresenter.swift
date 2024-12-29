import Cocoa

final class AlertPresenter {
    static let shared = AlertPresenter()
    
    private init() {}
    
    func showAlert(title: String,
                  message: String,
                  style: NSAlert.Style = .informational,
                  primaryButton: String = "OK",
                  secondaryButton: String? = nil,
                  window: NSWindow? = nil,
                  completion: ((NSApplication.ModalResponse) -> Void)? = nil) {
        
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: primaryButton)
        
        if let secondaryButton = secondaryButton {
            alert.addButton(withTitle: secondaryButton)
        }
        
        if let window = window {
            alert.beginSheetModal(for: window, completionHandler: completion)
        } else {
            let response = alert.runModal()
            completion?(response)
        }
    }
    
    func showAccessibilityAlert(completion: ((Bool) -> Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = "Accessibility Access Required"
        alert.informativeText = "Hot Text needs accessibility access to monitor keyboard events. Please grant access in System Settings > Privacy & Security > Accessibility"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        
        let response = alert.runModal()
        let shouldOpenSettings = response == .alertFirstButtonReturn
        
        if shouldOpenSettings {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
        
        completion?(shouldOpenSettings)
    }
    
    func showDeleteConfirmation(count: Int, window: NSWindow, completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Delete Selected Replacements"
        alert.informativeText = "Are you sure you want to delete \(count) selected replacement\(count == 1 ? "" : "s")?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        alert.beginSheetModal(for: window) { response in
            completion(response == .alertFirstButtonReturn)
        }
    }
} 