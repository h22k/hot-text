import Cocoa
import Combine

final class WindowManager: NSObject {
    static let shared = WindowManager()
    
    private var configWindow: NSWindow?
    private var configViewController: TextReplacementConfigViewController?
    private var listWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleShowConfigWindow(_:)), name: .showConfigWindow, object: nil)
        
        NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)
            .sink { [weak self] notification in
                if let window = notification.object as? NSWindow {
                    if window == self?.configWindow {
                        self?.configWindow = nil
                        self?.configViewController = nil
                    } else if window == self?.listWindow {
                        self?.listWindow = nil
                    } else if window == self?.settingsWindow {
                        self?.settingsWindow = nil
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleShowConfigWindow(_ notification: Notification) {
        let selectedText = notification.object as? String
        print("Received showConfigWindow notification with text:", selectedText ?? "none")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.showConfigWindow()
        }
    }
    
    private func centerWindowOnScreen(_ window: NSWindow) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        
        let x = screenFrame.origin.x + (screenFrame.width - windowFrame.width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - windowFrame.height) / 2
        
        window.setFrame(NSRect(x: x, y: y, width: windowFrame.width, height: windowFrame.height), display: true)
    }
    
    func showConfigWindow() {
        if let existingWindow = configWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let configVC = TextReplacementConfigViewController(textReplacementService: TextReplacementService.shared)
        configViewController = configVC
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 280),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Add Text Replacement"
        window.contentViewController = configVC
        
        window.setContentSize(configVC.view.fittingSize)
        
        window.setFrameAutosaveName("ConfigWindow")
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .windowBackgroundColor
        window.isMovableByWindowBackground = true
        window.hasShadow = true
        
        centerWindowOnScreen(window)
        
        window.delegate = self
        configWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showListWindow(with replacements: [String: String]) {
        if let existingWindow = listWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let listVC = ReplacementListViewController(textReplacementService: TextReplacementService.shared)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Text Replacements"
        window.contentViewController = listVC
        window.setFrameAutosaveName("ListWindow")
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        centerWindowOnScreen(window)
        listWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showSettingsWindow() {
        if let existingWindow = settingsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsVC = SettingsViewController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Settings"
        window.contentViewController = settingsVC
        window.setFrameAutosaveName("SettingsWindow")
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        centerWindowOnScreen(window)
        settingsWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension WindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        if window == configWindow {
            configWindow = nil
            configViewController = nil
        } else if window == listWindow {
            listWindow = nil
        } else if window == settingsWindow {
            settingsWindow = nil
        }
    }
} 
