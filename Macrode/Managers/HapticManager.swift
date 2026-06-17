#if canImport(UIKit)
import UIKit
#endif

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
#if canImport(UIKit)
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
#else
    enum FeedbackStyle {
        case light, medium, heavy, soft, rigid
    }
    enum FeedbackType {
        case success, warning, error
    }
    
    func impact(_ style: FeedbackStyle) {}
    func notification(_ type: FeedbackType) {}
    func selection() {}
#endif
}
