import Cocoa

class ReplacementListViewController: NSViewController {
    private let textReplacementService: TextReplacementService
    private var replacements: [(shortcut: String, replacement: String)] = []
    
    private lazy var contentStack: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var headerStack: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: "list.bullet", accessibilityDescription: "List")
        iconView.contentTintColor = .systemBlue
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])
        stack.addArrangedSubview(iconView)
        
        let titleLabel = NSTextField(labelWithString: "Text Replacements")
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .labelColor
        stack.addArrangedSubview(titleLabel)
        
        return stack
    }()
    
    private lazy var searchField: NSSearchField = {
        let field = NSSearchField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholderString = "Search replacements..."
        field.controlSize = .large
        field.target = self
        field.action = #selector(searchFieldChanged(_:))
        
        NSLayoutConstraint.activate([
            field.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return field
    }()
    
    private lazy var scrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        return scroll
    }()
    
    private lazy var tableView: NSTableView = {
        let table = NSTableView()
        table.style = .inset
        table.backgroundColor = .clear
        table.headerView = nil
        table.rowHeight = 44
        table.gridStyleMask = []
        table.selectionHighlightStyle = .regular
        table.usesAutomaticRowHeights = true
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ReplacementColumn"))
        column.isEditable = false
        table.addTableColumn(column)
        
        table.delegate = self
        table.dataSource = self
        table.menu = createContextMenu()
        table.target = self
        table.doubleAction = #selector(tableViewDoubleClicked(_:))
        
        return table
    }()
    
    private func createContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Edit", action: #selector(editReplacement(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Delete", action: #selector(deleteReplacement(_:)), keyEquivalent: ""))
        return menu
    }
    
    @objc private func tableViewDoubleClicked(_ sender: Any) {
        editReplacement(sender)
    }
    
    @objc private func editReplacement(_ sender: Any) {
        guard tableView.selectedRow >= 0 else { return }
        let replacement = replacements[tableView.selectedRow]
        
        let alert = NSAlert()
        alert.messageText = "Edit Replacement"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        
        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 80))
        
        let shortcutField = NSTextField(frame: NSRect(x: 0, y: 40, width: 300, height: 24))
        shortcutField.placeholderString = "Shortcut"
        shortcutField.stringValue = replacement.shortcut
        accessoryView.addSubview(shortcutField)
        
        let replacementField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        replacementField.placeholderString = "Replacement"
        replacementField.stringValue = replacement.replacement
        accessoryView.addSubview(replacementField)
        
        alert.accessoryView = accessoryView
        
        alert.beginSheetModal(for: view.window ?? NSWindow()) { response in
            guard response == .alertFirstButtonReturn else { return }
            
            let newShortcut = shortcutField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let newReplacement = replacementField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !newShortcut.isEmpty && !newReplacement.isEmpty else {
                self.showAlert(title: "Error", message: "Both fields are required")
                return
            }
            
            do {
                try self.textReplacementService.updateReplacement(replacement.shortcut, newShortcut: newShortcut, newReplacement: newReplacement)
                self.replacements = self.textReplacementService.getAllReplacements().map { ($0.key, $0.value) }
                self.tableView.reloadData()
                self.showAlert(title: "Success", message: "Replacement updated successfully")
            } catch {
                self.showAlert(title: "Error", message: "Failed to update replacement: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func deleteReplacement(_ sender: Any) {
        guard tableView.selectedRow >= 0 else { return }
        let replacement = replacements[tableView.selectedRow]
        
        let alert = NSAlert()
        alert.messageText = "Delete Replacement"
        alert.informativeText = "Are you sure you want to delete this replacement?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        alert.beginSheetModal(for: view.window ?? NSWindow()) { response in
            guard response == .alertFirstButtonReturn else { return }
            
            do {
                try self.textReplacementService.removeReplacement(for: replacement.shortcut)
                self.replacements = self.textReplacementService.getAllReplacements().map { ($0.key, $0.value) }
                self.tableView.reloadData()
                self.showAlert(title: "Success", message: "Replacement deleted successfully")
            } catch {
                self.showAlert(title: "Error", message: "Failed to delete replacement: \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = title == "Error" ? .critical : .informational
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: view.window ?? NSWindow())
    }
    
    init(textReplacementService: TextReplacementService) {
        self.textReplacementService = textReplacementService
        super.init(nibName: nil, bundle: nil)
        self.title = "Text Replacements"
        self.replacements = textReplacementService.getAllReplacements().map { ($0.key, $0.value) }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let container = NSView()
        view = container
        
        // Add content stack
        container.addSubview(contentStack)
        
        // Add header
        contentStack.addArrangedSubview(headerStack)
        
        // Add search field
        contentStack.addArrangedSubview(searchField)
        
        // Add table
        scrollView.documentView = tableView
        contentStack.addArrangedSubview(scrollView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 480),
            container.heightAnchor.constraint(equalToConstant: 600),
            
            contentStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24),
            
            scrollView.heightAnchor.constraint(equalToConstant: 400)
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set window properties
        if let window = view.window {
            window.styleMask = [.titled, .closable, .resizable]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = .windowBackgroundColor
            window.isMovableByWindowBackground = true
            window.setContentSize(NSSize(width: 480, height: 600))
            
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
    
    @objc private func searchFieldChanged(_ sender: NSSearchField) {
        let searchText = sender.stringValue.lowercased()
        if searchText.isEmpty {
            replacements = textReplacementService.getAllReplacements().map { ($0.key, $0.value) }
        } else {
            replacements = textReplacementService.getAllReplacements()
                .map { ($0.key, $0.value) }
                .filter { replacement in
                    replacement.0.lowercased().contains(searchText) ||
                    replacement.1.lowercased().contains(searchText)
                }
        }
        tableView.reloadData()
    }
}

extension ReplacementListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = NSTableCellView()
        cell.identifier = NSUserInterfaceItemIdentifier("ReplacementCell")
        
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: cell.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -8)
        ])
        
        let shortcutLabel = NSTextField(labelWithString: replacements[row].shortcut)
        shortcutLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        shortcutLabel.textColor = .labelColor
        stack.addArrangedSubview(shortcutLabel)
        
        let replacementLabel = NSTextField(labelWithString: replacements[row].replacement)
        replacementLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        replacementLabel.textColor = .secondaryLabelColor
        stack.addArrangedSubview(replacementLabel)
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 60
    }
}

extension ReplacementListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return replacements.count
    }
} 