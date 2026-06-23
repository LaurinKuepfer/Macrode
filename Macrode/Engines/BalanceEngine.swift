import Foundation

struct BalanceEngine {
    
    struct BalanceResult {
        var calorieAdjustment: Double // Deprecated, kept for API compatibility, always 0
        var weeklyEnergyOffset: Double
    }
    
    static func calculateBalance(
        for date: Date,
        allLogs: [DailyLogData],
        allMeals: [ConsumedMealData],
        userGoal: GoalType
    ) -> BalanceResult? {
        let calendar = Calendar.current
        var calendarWithMonday = calendar
        calendarWithMonday.firstWeekday = 2
        
        let targetStartOfDay = calendarWithMonday.startOfDay(for: date)
        
        guard let earliestLogDate = allLogs.map({ $0.date }).min() else { return nil }
        let earliestLogStartOfDay = calendarWithMonday.startOfDay(for: earliestLogDate)
        
        // Use a 7-day rolling average instead of 14 to be more responsive
        guard let startOf7Days = calendarWithMonday.date(byAdding: .day, value: -7, to: targetStartOfDay) else { return nil }
        let calculationStartDate = max(startOf7Days, earliestLogStartOfDay)
        
        if calculationStartDate >= targetStartOfDay {
            return nil
        }
        
        var totalConsumed: Double = 0
        var totalBaseTarget: Double = 0
        
        // O(1) Lookups to prevent O(N * D) frame drops
        let mealsByDay = Dictionary(grouping: allMeals) { calendarWithMonday.startOfDay(for: $0.consumedAt) }
        let logsByDay = Dictionary(grouping: allLogs) { calendarWithMonday.startOfDay(for: $0.date) }
        
        var currentDate = calculationStartDate
        while currentDate < targetStartOfDay {
            guard let nextDay = calendarWithMonday.date(byAdding: .day, value: 1, to: currentDate) else { break }
            
            let daysMeals = mealsByDay[currentDate] ?? []
            let daysCalories = daysMeals.reduce(0) { $0 + $1.calories }
            
            // Exclude "Flexible Day" or check if log says so? 
            // We just strictly use historical target.
            var daysBaseTarget: Double = 2200
            if let log = logsByDay[currentDate]?.first {
                daysBaseTarget = log.calorieTarget // NEVER REWRITE HISTORY
            }
            
            totalConsumed += daysCalories
            totalBaseTarget += daysBaseTarget
            
            currentDate = nextDay
        }
        
        let weeklyEnergyOffset = totalConsumed - totalBaseTarget
        
        // Gently adjust the daily target by spreading the weekly energy offset over the next 7 days.
        // A positive offset means overeating, so adjustment is negative.
        let calorieAdjustment = -(weeklyEnergyOffset / 7.0)
        return BalanceResult(calorieAdjustment: calorieAdjustment, weeklyEnergyOffset: weeklyEnergyOffset)
    }
}
