import Foundation
import SwiftData

@Model
class TextReplacement {
    var shortcut: String
    var replacement: String
    
    init(shortcut: String, replacement: String) {
        self.shortcut = shortcut
        self.replacement = replacement
    }
} 