import Cocoa


class SettingsViewController: NSViewController {
    private let shortcutRecorder: ShortcutRecorder
    private let shortcutService: ShortcutService
    private var triggerRecorder: ShortcutRecorder!
    
    init() {
        self.shortcutRecorder = ShortcutRecorder(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        self.shortcutService = ShortcutService.shared
        super.init(nibName: nil, bundle: nil)
        self.title = "Settings"
        
        // Initialize trigger recorder
        self.triggerRecorder = ShortcutRecorder(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        
        // Set up delegates
        self.shortcutRecorder.delegate = self
        self.triggerRecorder.delegate = self
        
        // Configure recorders
        self.shortcutRecorder.requiresModifiers = true  // Global shortcut requires modifiers
        self.triggerRecorder.requiresModifiers = false  // Trigger key is single key
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let container = NSView()    
        view = container
        
        // Create sections stack
        let sectionsStack = NSStackView()
        sectionsStack.orientation = .vertical
        sectionsStack.spacing = 16
        sectionsStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(sectionsStack)
        
        // Add shortcut section
        let shortcutSection = createShortcutSection()
        sectionsStack.addArrangedSubview(shortcutSection)
        
        // Add trigger key section
        let triggerSection = createTriggerSection()
        sectionsStack.addArrangedSubview(triggerSection)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Container size
            container.widthAnchor.constraint(equalToConstant: 480),
            container.heightAnchor.constraint(equalToConstant: 360),
            
            // Sections stack
            sectionsStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            sectionsStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            sectionsStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            sectionsStack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20)
        ])
        
        // Load current settings
        loadCurrentSettings()
    }
    
    private func createShortcutSection() -> NSView {
        let section = createSection()
        
        // Section header
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(headerStack)
        
        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keyboard")
        iconView.contentTintColor = .secondaryLabelColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        headerStack.addArrangedSubview(iconView)
        
        let titleLabel = NSTextField(labelWithString: "Global Shortcut")
        titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        titleLabel.textColor = .labelColor
        headerStack.addArrangedSubview(titleLabel)
        
        // Content stack
        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(contentStack)
        
        // Shortcut row
        let shortcutRow = NSStackView()
        shortcutRow.orientation = .horizontal
        shortcutRow.spacing = 12
        shortcutRow.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(shortcutRow)
        
        let shortcutLabel = NSTextField(labelWithString: "Activation Shortcut:")
        shortcutLabel.font = .systemFont(ofSize: NSFont.systemFontSize)
        shortcutLabel.textColor = .secondaryLabelColor
        shortcutRow.addArrangedSubview(shortcutLabel)
        
        shortcutRecorder.translatesAutoresizingMaskIntoConstraints = false
        shortcutRow.addArrangedSubview(shortcutRecorder)
        
        // Description
        let shortcutDescription = NSTextField(wrappingLabelWithString: "Use this shortcut to quickly add new text replacements. When pressed, if any text is selected, it will be automatically copied to the replacement field.")
        shortcutDescription.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        shortcutDescription.textColor = .secondaryLabelColor
        contentStack.addArrangedSubview(shortcutDescription)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Header stack
            headerStack.topAnchor.constraint(equalTo: section.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(lessThanOrEqualTo: section.trailingAnchor, constant: -16),
            
            // Icon size
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
            
            // Content stack
            contentStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: section.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: section.bottomAnchor, constant: -16),
            
            // Shortcut recorder
            shortcutRecorder.widthAnchor.constraint(equalToConstant: 200),
            shortcutRecorder.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return section
    }
    
    private func createTriggerSection() -> NSView {
        let section = createSection()
        
        // Section header
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(headerStack)
        
        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: "return", accessibilityDescription: "Trigger")
        iconView.contentTintColor = .secondaryLabelColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        headerStack.addArrangedSubview(iconView)
        
        let titleLabel = NSTextField(labelWithString: "Trigger Key")
        titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        titleLabel.textColor = .labelColor
        headerStack.addArrangedSubview(titleLabel)
        
        // Content stack
        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        section.addSubview(contentStack)
        
        // Trigger key row
        let triggerRow = NSStackView()
        triggerRow.orientation = .horizontal
        triggerRow.spacing = 12
        triggerRow.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(triggerRow)
        
        let triggerLabel = NSTextField(labelWithString: "Trigger Key:")
        triggerLabel.font = .systemFont(ofSize: NSFont.systemFontSize)
        triggerLabel.textColor = .secondaryLabelColor
        triggerRow.addArrangedSubview(triggerLabel)
        
        triggerRecorder.translatesAutoresizingMaskIntoConstraints = false
        triggerRow.addArrangedSubview(triggerRecorder)
        
        // Description
        let triggerDescription = NSTextField(wrappingLabelWithString: "Press this key after typing a shortcut to trigger the replacement. Default is Tab key.")
        triggerDescription.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        triggerDescription.textColor = .secondaryLabelColor
        contentStack.addArrangedSubview(triggerDescription)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Header stack
            headerStack.topAnchor.constraint(equalTo: section.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(lessThanOrEqualTo: section.trailingAnchor, constant: -16),
            
            // Icon size
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
            
            // Content stack
            contentStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: section.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: section.bottomAnchor, constant: -16),
            
            // Trigger recorder
            triggerRecorder.widthAnchor.constraint(equalToConstant: 200),
            triggerRecorder.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return section
    }
    
    private func createSection() -> NSView {
        let section = NSView()
        section.translatesAutoresizingMaskIntoConstraints = false
        section.wantsLayer = true
        
        // Modern styling
        section.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        section.layer?.cornerRadius = 8
        section.layer?.borderWidth = 1
        section.layer?.borderColor = NSColor.separatorColor.cgColor
        
        // Add subtle shadow
        section.shadow = NSShadow()
        section.layer?.shadowColor = NSColor.black.withAlphaComponent(0.1).cgColor
        section.layer?.shadowOffset = NSSize(width: 0, height: 1)
        section.layer?.shadowRadius = 2
        section.layer?.shadowOpacity = 1
        
        return section
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shortcutRecorder.delegate = self
        
        // Set window properties
        if let window = view.window {
            window.styleMask = [.titled, .closable]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .visible
            window.backgroundColor = .windowBackgroundColor
            window.setContentSize(NSSize(width: 480, height: 360))
            
            // Center window
            if let screen = window.screen {
                let screenRect = screen.visibleFrame
                let windowRect = window.frame
                let x = screenRect.midX - windowRect.width / 2
                let y = screenRect.midY - windowRect.height / 2
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
        }
    }
    
    private func loadCurrentSettings() {
        // Load global shortcut
        if let shortcut = shortcutService.getCurrentShortcut() {
            shortcutRecorder.setShortcut(keyCode: shortcut.keyCode, modifierFlags: shortcut.modifierFlags)
        }
        
        // Load trigger key
        let triggerKey = shortcutService.getCurrentTriggerKey()
        triggerRecorder.setShortcut(keyCode: triggerKey, modifierFlags: [])
    }
}

extension SettingsViewController: ShortcutRecorderDelegate {
    func shortcutRecorder(_ recorder: ShortcutRecorder, didChangeKeyCode keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) {
        if recorder === shortcutRecorder {
            // For global shortcut, allow modifiers
            print("Updating global shortcut - KeyCode: \(keyCode), Modifiers: \(modifierFlags)")
            shortcutService.updateShortcut(keyCode: keyCode, modifierFlags: modifierFlags)
        } else if recorder === triggerRecorder {
            // For trigger key, ignore modifiers
            print("Updating trigger key - KeyCode: \(keyCode)")
            shortcutService.updateTriggerKey(keyCode)
        }
    }
    
    func shortcutRecorderShouldBeginRecording(_ recorder: ShortcutRecorder) -> Bool {
        return true
    }
    
    func shortcutRecorderDidEndRecording(_ recorder: ShortcutRecorder) {
        if recorder === triggerRecorder {
            // For trigger key, clear any modifiers
            let currentKey = shortcutService.getCurrentTriggerKey()
            triggerRecorder.setShortcut(keyCode: currentKey, modifierFlags: [])
        }
    }
} 
