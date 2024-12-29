import Foundation
import SwiftData

final class SwiftDataRepository: TextReplacementRepository {
    static let shared = SwiftDataRepository()
    
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?
    
    private init() {
        setupSwiftData()
    }
    
    private func setupSwiftData() {
        do {
            let schema = Schema([TextReplacement.self])
            let modelConfiguration = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer!)
        } catch {
            print("Failed to setup SwiftData:", error)
        }
    }
    
    func getAllReplacements() -> [TextReplacement] {
        guard let context = modelContext else { return [] }
        
        do {
            let descriptor = FetchDescriptor<TextReplacement>()
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch replacements:", error)
            return []
        }
    }
    
    func save(_ replacement: TextReplacement) throws {
        guard let context = modelContext else {
            throw PersistenceError.contextNotAvailable
        }
        
        context.insert(replacement)
        try context.save()
        NotificationCenter.default.post(name: .replacementsDidUpdate, object: nil)
    }
    
    func delete(_ replacement: TextReplacement) throws {
        guard let context = modelContext else {
            throw PersistenceError.contextNotAvailable
        }
        
        context.delete(replacement)
        try context.save()
        NotificationCenter.default.post(name: .replacementsDidUpdate, object: nil)
    }
    
    func deleteAll() throws {
        guard let context = modelContext else {
            throw PersistenceError.contextNotAvailable
        }
        
        let existingItems = getAllReplacements()
        existingItems.forEach { context.delete($0) }
        try context.save()
        NotificationCenter.default.post(name: .replacementsDidUpdate, object: nil)
    }
}

enum PersistenceError: Error {
    case contextNotAvailable
} 