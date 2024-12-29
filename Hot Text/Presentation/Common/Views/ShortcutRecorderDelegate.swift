import Cocoa

protocol ShortcutRecorderDelegate: AnyObject {
    func shortcutRecorder(_ recorder: ShortcutRecorder, didChangeKeyCode keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags)
} 