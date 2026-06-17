import StoreKit
import SwiftUI

class ReviewManager {
    static let shared = ReviewManager()
    
    @AppStorage("lastReviewPromptDate") private var lastReviewPromptDate: Double = 0
    @AppStorage("highestStreakReviewed") private var highestStreakReviewed: Int = 0
    
    private init() {}
    
    func checkAndPromptReview(currentStreak: Int) {
        let milestones = [7, 14, 30, 60, 100]
        
        guard milestones.contains(currentStreak), currentStreak > highestStreakReviewed else {
            return
        }
        
        let now = Date().timeIntervalSince1970
        let thirtyDays: TimeInterval = 30 * 24 * 60 * 60
        guard now - lastReviewPromptDate > thirtyDays else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                if #available(iOS 18.0, *) {
                    AppStore.requestReview(in: windowScene)
                } else {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
                self.lastReviewPromptDate = now
                self.highestStreakReviewed = currentStreak
            }
        }
    }
}
