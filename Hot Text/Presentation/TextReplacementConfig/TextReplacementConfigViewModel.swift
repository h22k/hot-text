import Foundation
import Combine

final class TextReplacementConfigViewModel {
    private let replacementService: TextReplacementService
    private var cancellables = Set<AnyCancellable>()
    
    @Published var shortcut: String = ""
    @Published var replacement: String = ""
    @Published var errorMessage: String?
    
    init(replacementService: TextReplacementService = .shared) {
        self.replacementService = replacementService
    }
    
    func addReplacement() -> Bool {
        guard !shortcut.isEmpty && !replacement.isEmpty else {
            errorMessage = "Both shortcut and replacement text are required."
            return false
        }
        
        do {
            try replacementService.addReplacement(shortcut, replacement: replacement)
            return true
        } catch {
            errorMessage = "Failed to save replacement: \(error.localizedDescription)"
            return false
        }
    }
} 