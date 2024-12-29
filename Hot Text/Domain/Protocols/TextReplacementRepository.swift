protocol TextReplacementRepository {
    func getAllReplacements() -> [TextReplacement]
    func save(_ replacement: TextReplacement) throws
    func delete(_ replacement: TextReplacement) throws
    func deleteAll() throws
} 