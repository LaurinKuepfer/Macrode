import XCTest
@testable import Macrode

final class BalanceEngineTests: XCTestCase {

    func testCalculateBalance_Maintain() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var logs = [DailyLogData]()
        var meals = [ConsumedMealData]()
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            // Target is 2000
            let log = DailyLog(date: date, calorieTarget: 2000, bodyWeight: 80.0)
            logs.append(DailyLogData(from: log))
            
            // Consumed 2000
            let meal = ConsumedMeal(name: "Test", calories: 2000, protein: 150, carbs: 200, fat: 60, consumedAt: date)
            meals.append(ConsumedMealData(from: meal))
        }
        
        let result = BalanceEngine.calculateBalance(for: today, allLogs: logs, allMeals: meals, userGoal: .maintain)
        
        XCTAssertNotNil(result)
        // Offset should be 0, adjustment 0
        XCTAssertEqual(result!.weeklyEnergyOffset, 0.0)
        XCTAssertEqual(result!.calorieAdjustment, 0.0)
    }
    
    func testCalculateBalance_Surplus() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var logs = [DailyLogData]()
        var meals = [ConsumedMealData]()
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            // Target is 2000
            let log = DailyLog(date: date, calorieTarget: 2000, bodyWeight: 80.0)
            logs.append(DailyLogData(from: log))
            
            // Consumed 2100 -> surplus of 100/day
            let meal = ConsumedMeal(name: "Test", calories: 2100, protein: 150, carbs: 200, fat: 60, consumedAt: date)
            meals.append(ConsumedMealData(from: meal))
        }
        
        let result = BalanceEngine.calculateBalance(for: today, allLogs: logs, allMeals: meals, userGoal: .maintain)
        
        XCTAssertNotNil(result)
        // Offset should be +700 (100 * 7)
        XCTAssertEqual(result!.weeklyEnergyOffset, 700.0)
        // Adjustment should be -100 (spread over 7 days)
        XCTAssertEqual(result!.calorieAdjustment, -100.0)
    }
}
