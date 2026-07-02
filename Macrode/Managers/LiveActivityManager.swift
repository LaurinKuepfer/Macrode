import Foundation
import ActivityKit

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var isStartingActivity = false
    
    private init() {}
    
    func startFastingActivity(caloriesLeft: Int, fastingHours: Double) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        endAllActivities()
        
        let attributes = MacrodeAttributes(name: "Fasting & Calories")
        let contentState = MacrodeAttributes.ContentState(caloriesLeft: caloriesLeft, fastingHours: fastingHours)
        
        if #available(iOS 16.2, *) {
            let activityContent = ActivityContent(state: contentState, staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date()))
            
            do {
                _ = try Activity.request(attributes: attributes, content: activityContent)
            } catch {
                print("Error starting Live Activity: \(error.localizedDescription)")
            }
        }
    }
    
    func updateOrStartFastingActivity(caloriesLeft: Int, fastingHours: Double) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if #available(iOS 16.2, *) {
            if Activity<MacrodeAttributes>.activities.isEmpty {
                if !isStartingActivity {
                    isStartingActivity = true
                    startFastingActivity(caloriesLeft: caloriesLeft, fastingHours: fastingHours)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.isStartingActivity = false
                    }
                }
            } else {
                updateFastingActivity(caloriesLeft: caloriesLeft, fastingHours: fastingHours)
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
