import Cocoa

protocol KeyboardEventHandler: AnyObject {
    var isTracking: Bool { get set }
    var currentBuffer: String { get set }
    
    func handleKeyPress(_ event: NSEvent)
    func startTracking()
    func stopTracking()
    func clearBuffer()
    func appendToBuffer(_ character: String)
    func removeLastCharacter()
} 