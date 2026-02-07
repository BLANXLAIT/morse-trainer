import UIKit

@MainActor
class HapticManager {
    static let shared = HapticManager()
    
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        // Prepare generators for minimal latency
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    /// Play haptic feedback for a dit (short tap)
    func playDit() {
        lightImpactGenerator.impactOccurred(intensity: 0.7)
        lightImpactGenerator.prepare() // Prepare for next use
    }
    
    /// Play haptic feedback for a dah (longer, stronger tap)
    func playDah() {
        mediumImpactGenerator.impactOccurred(intensity: 1.0)
        mediumImpactGenerator.prepare() // Prepare for next use
    }
    
    /// Play success feedback
    func playSuccess() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    /// Play error feedback
    func playError() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    /// Play a subtle tap for general interaction
    func playTap() {
        mediumImpactGenerator.impactOccurred(intensity: 0.5)
        mediumImpactGenerator.prepare()
    }
}
