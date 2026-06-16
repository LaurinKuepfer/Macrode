import StoreKit
import SwiftUI

class ReviewManager {
    static let shared = ReviewManager()
    
    @AppStorage("lastReviewPromptDate") private var lastReviewPromptDate: Double = 0
    @AppStorage("highestStreakReviewed") private var highestStreakReviewed: Int = 0
    
    private init() {}
    
    func checkAndPromptReview(currentStreak: Int) {
        // We want to ask for a review when the user hits a meaningful milestone.
        // Good milestones: 7 days, 14 days, 30 days, etc.
        let milestones = [7, 14, 30, 60, 100]
        
        // Ensure we haven't already asked for this specific streak milestone
        guard milestones.contains(currentStreak), currentStreak > highestStreakReviewed else {
            return
        }
        
        // Ensure we haven't asked recently (e.g., within the last 30 days) to avoid spamming
        let now = Date().timeIntervalSince1970
        let thirtyDays: TimeInterval = 30 * 24 * 60 * 60
        guard now - lastReviewPromptDate > thirtyDays else {
            return
        }
        
        // Trigger the review prompt
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
