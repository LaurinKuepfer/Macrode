import Foundation

struct ForgivenessEngine {
    
    struct ForgivenessResult {
        var calorieAdjustment: Double
        var weeklyBankBalance: Double
    }
    
    static func calculateForgiveness(
        for date: Date,
        allLogs: [DailyLog],
        allMeals: [ConsumedMeal],
        userGoal: GoalType
    ) -> ForgivenessResult? {
        let calendar = Calendar.current
        var calendarWithMonday = calendar
        calendarWithMonday.firstWeekday = 2
        
        let targetStartOfDay = calendarWithMonday.startOfDay(for: date)
        
        guard let earliestLogDate = allLogs.map({ $0.date }).min() else { return nil }
        let earliestLogStartOfDay = calendarWithMonday.startOfDay(for: earliestLogDate)
        
        let startOf14Days = calendarWithMonday.date(byAdding: .day, value: -14, to: targetStartOfDay)!
        let calculationStartDate = max(startOf14Days, earliestLogStartOfDay)
        
        if calculationStartDate >= targetStartOfDay {
            return nil
        }
        
        var totalConsumed: Double = 0
        var totalBaseTarget: Double = 0
        
        var currentDate = calculationStartDate
        while currentDate < targetStartOfDay {
            let nextDay = calendarWithMonday.date(byAdding: .day, value: 1, to: currentDate)!
            
            let daysMeals = allMeals.filter { $0.consumedAt >= currentDate && $0.consumedAt < nextDay }
            let daysCalories = daysMeals.reduce(0) { $0 + $1.calories }
            
            var daysBaseTarget: Double = 2200
            if let log = allLogs.first(where: { calendarWithMonday.isDate($0.date, inSameDayAs: currentDate) }) {
                daysBaseTarget = log.calorieTarget
                if let tdee = MetabolismEngine.calculateTrueTDEE(dailyLogs: allLogs, allMeals: allMeals) {
                    switch userGoal {
                    case .lose: daysBaseTarget = tdee - 500
                    case .gain: daysBaseTarget = tdee + 300
                    case .maintain: daysBaseTarget = tdee
                    }
                }
            }
            
            totalConsumed += daysCalories
            totalBaseTarget += daysBaseTarget
            
            currentDate = nextDay
        }
        
        let weeklyBankBalance = totalConsumed - totalBaseTarget
        
        if abs(weeklyBankBalance) <= 200 {
            return nil
        }
        
        var dailyAdjustment = -weeklyBankBalance / 14.0
        
        if dailyAdjustment > 500 {
            dailyAdjustment = 500
        } else if dailyAdjustment < -500 {
            dailyAdjustment = -500
        }
        
        return ForgivenessResult(calorieAdjustment: dailyAdjustment, weeklyBankBalance: weeklyBankBalance)
    }
}
