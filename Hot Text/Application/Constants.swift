import Foundation

enum Constants {
    enum Keyboard {
        static let backspaceKeyCode: UInt16 = 0x33
        static let tabKeyCode: UInt16 = 48
        static let spaceKeyCode: UInt16 = 49
        static let triggerCharacter = "/"
    }
    
    enum UI {
        static let defaultWindowWidth: CGFloat = 600
        static let defaultWindowHeight: CGFloat = 400
        static let defaultTableColumnWidth: CGFloat = 200
        static let defaultTableColumnPadding: CGFloat = 20
        static let defaultAnimationDuration: TimeInterval = 0.2
    }
    
    enum Storage {
        static let maxBufferSize: Int = 50
        static let keyDelayInterval: TimeInterval = 0.01
        static let replacementDelayInterval: TimeInterval = 0.05
    }
} 