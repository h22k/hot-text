import Foundation
import Combine

final class TextReplacementService {
    static let shared = TextReplacementService()
    
    @Published private(set) var replacements: [String: String] = [:]
    private let simulator = KeyboardEventSimulator.shared
    
    private init() {
        loadReplacements()
    }
    
    private func loadReplacements() {
        if let data = UserDefaults.standard.dictionary(forKey: "TextReplacements") as? [String: String] {
            replacements = data
        }
    }
    
    private func saveReplacements() {
        UserDefaults.standard.set(replacements, forKey: "TextReplacements")
    }
    
    func addReplacement(_ shortcut: String, replacement: String) throws {
        replacements[shortcut] = replacement
        saveReplacements()
        NotificationCenter.default.post(name: .replacementsDidUpdate, object: nil)
    }
    
    func removeReplacement(for shortcut: String) {
        replacements.removeValue(forKey: shortcut)
        saveReplacements()
        NotificationCenter.default.post(name: .replacementsDidUpdate, object: nil)
    }
    
    func getReplacement(for shortcut: String) -> String? {
        return replacements[shortcut]
    }
    
    func hasReplacement(for shortcut: String) -> Bool {
        return replacements[shortcut] != nil
    }
    
    func getAllReplacements() -> [String: String] {
        return replacements
    }
    
    func updateReplacement(_ oldShortcut: String, newShortcut: String, newReplacement: String) throws {
        // Remove old shortcut if it's different
        if oldShortcut != newShortcut {
            replacements.removeValue(forKey: oldShortcut)
        }
        
        // Add new replacement
        replacements[newShortcut] = newReplacement
        saveReplacements()
        NotificationCenter.default.post(name: .replacementsDidUpdate, object: nil)
    }
    
    func performReplacement(for shortcut: String) -> Bool {
        guard let replacement = replacements[shortcut] else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .replacementDidFail, object: nil)
            }
            return false
        }
        
        // Get current trigger key
        let triggerKeyCode = ShortcutService.shared.getCurrentTriggerKey()
        
        // For space trigger, delete the trigger key too
        // For other triggers (tab, etc.), only delete the shortcut
        let deleteCount = triggerKeyCode == 0x31 ? shortcut.count + 1 : shortcut.count
        simulator.deleteCharacters(count: deleteCount)
        
        // Insert replacement
        simulator.insertText(replacement)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .replacementDidComplete, object: nil)
        }
        return true
    }
} 