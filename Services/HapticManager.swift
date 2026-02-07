import UIKit

@MainActor
class HapticManager {
    static let shared = HapticManager()
    
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        // Prepare generators for minimal latency
        impactGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    /// Play haptic feedback for a dit (short tap)
    func playDit() {
        let lightGenerator = UIImpactFeedbackGenerator(style: .light)
        lightGenerator.impactOccurred(intensity: 0.7)
    }
    
    /// Play haptic feedback for a dah (longer, stronger tap)
    func playDah() {
        let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
        mediumGenerator.impactOccurred(intensity: 1.0)
    }
    
    /// Play success feedback
    func playSuccess() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Play error feedback
    func playError() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Play a subtle tap for general interaction
    func playTap() {
        impactGenerator.impactOccurred(intensity: 0.5)
    }
}
