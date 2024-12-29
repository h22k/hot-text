import Foundation
import Combine

final class ReplacementListViewModel {
    private let replacementService: TextReplacementService
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var replacements: [(shortcut: String, replacement: String)] = []
    
    init(replacementService: TextReplacementService = .shared) {
        self.replacementService = replacementService
        setupBindings()
    }
    
    private func setupBindings() {
        replacementService.$replacements
            .map { dict in
                dict.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
            }
            .assign(to: &$replacements)
        
        NotificationCenter.default.publisher(for: .replacementsDidUpdate)
            .sink { [weak self] _ in
                self?.loadReplacements()
            }
            .store(in: &cancellables)
    }
    
    private func loadReplacements() {
        replacements = replacementService.replacements
            .map { ($0.key, $0.value) }
            .sorted { $0.0 < $1.0 }
    }
    
    func deleteReplacements(at indexSet: IndexSet) {
        let shortcutsToDelete = indexSet.map { replacements[$0].shortcut }
        // Implementation of delete functionality
    }
} 