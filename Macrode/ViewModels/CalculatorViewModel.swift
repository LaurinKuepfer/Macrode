import Foundation
import SwiftData
import SwiftUI

@Observable
class CalculatorViewModel {
    var isMale: Bool = true
    var age: Double?
    var heightCM: Double?
    var weightKG: Double?
    var activityLevel: CalculatorView.ActivityLevel = .sedentary
    
    func load(from log: DailyLog) {
        if let w = log.bodyWeight {
            self.weightKG = w
        }
    }
    
    var isInputValid: Bool {
        return age != nil && heightCM != nil && weightKG != nil
    }
    
    func calculateAndSave(dailyLog: DailyLog, context: ModelContext, goal: GoalType) {
        let w = weightKG ?? 70.0
        let h = heightCM ?? 170.0
        let a = age ?? 30.0
        
        var bmr = (10.0 * w) + (6.25 * h) - (5.0 * a)
        bmr += isMale ? 5.0 : -161.0
        
        var tdee = bmr * activityLevel.multiplier
        
        if goal == .lose { tdee -= 500 }
        if goal == .gain { tdee += 300 }
        
        let roundedTdee = round(tdee)
        let proteinPerKg = (activityLevel == .active || activityLevel == .athlete || goal == .gain) ? 2.0 : 1.6
        let proteinTarget = round(w * proteinPerKg)
        let fatTarget = round((tdee * 0.25) / 9.0)
        let remainingCals = tdee - (proteinTarget * 4.0) - (fatTarget * 9.0)
        let carbsTarget = round(max(0, remainingCals / 4.0))
        
        dailyLog.calorieTarget = roundedTdee
        dailyLog.proteinTarget = proteinTarget
        dailyLog.carbsTarget = carbsTarget
        dailyLog.fatTarget = fatTarget
        dailyLog.bodyWeight = w
        dailyLog.waterTargetML = Int((w / 20.0) * 1000)
        
        try? context.save()
    }
}
