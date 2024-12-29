import SwiftUI

@main
class Hot_TextApp: NSObject, NSApplicationDelegate {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize app delegate
        _ = AppDelegate()
    }
} 
