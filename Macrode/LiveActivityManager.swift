import Foundation
import ActivityKit

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private init() {}
    
    func startFastingActivity(caloriesLeft: Int, fastingHours: Double) {
        // Only start if supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        // End existing activities first
        endAllActivities()
        
        let attributes = MacrodeAttributes(name: "Fasting & Calories")
        let contentState = MacrodeAttributes.ContentState(caloriesLeft: caloriesLeft, fastingHours: fastingHours)
        
        // Swift 5.9 / iOS 16.2+ Activity Content API
        if #available(iOS 16.2, *) {
            let activityContent = ActivityContent(state: contentState, staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date()))
            
            do {
                _ = try Activity.request(attributes: attributes, content: activityContent)
            } catch {
                print("Error starting Live Activity: \(error.localizedDescription)")
            }
        }
    }
    
    func updateFastingActivity(caloriesLeft: Int, fastingHours: Double) {
        Task {
            let contentState = MacrodeAttributes.ContentState(caloriesLeft: caloriesLeft, fastingHours: fastingHours)
            
            if #available(iOS 16.2, *) {
                let activityContent = ActivityContent(state: contentState, staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date()))
                for activity in Activity<MacrodeAttributes>.activities {
                    await activity.update(activityContent)
                }
            }
        }
    }
    
    func endAllActivities() {
        Task {
            for activity in Activity<MacrodeAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
