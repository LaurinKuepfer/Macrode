import XCTest
@testable import Macrode

final class MetabolismEngineTests: XCTestCase {

    func testCalculateTrueTDEE_MaintainWeight() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var logs = [DailyLogData]()
        var meals = [ConsumedMealData]()
        
        // 14 days of data, weight exactly the same
        for i in 0..<14 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            
            let log = DailyLog(date: date, calorieTarget: 2000, bodyWeight: 80.0)
            logs.append(DailyLogData(from: log))
            
            // Log 2000 calories each day
            let meal = ConsumedMeal(name: "Test Meal", calories: 2000, protein: 150, carbs: 200, fat: 60, consumedAt: date)
            meals.append(ConsumedMealData(from: meal))
        }
        
        let tdee = MetabolismEngine.calculateTrueTDEE(dailyLogs: logs, allMeals: meals)
        
        // Weight didn't change, eating 2000 cals -> TDEE should be 2000
        XCTAssertEqual(tdee, 2000.0, accuracy: 0.1)
    }
    
    func testCalculateTrueTDEE_LostWeight() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var logs = [DailyLogData]()
        var meals = [ConsumedMealData]()
        
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let weight = 80.0 + (Double(i) * 0.1) // 80.0 today, 80.9 9 days ago
            
            let log = DailyLog(date: date, calorieTarget: 2000, bodyWeight: weight)
            logs.append(DailyLogData(from: log))
            
            let meal = ConsumedMeal(name: "Test Meal", calories: 2000, protein: 150, carbs: 200, fat: 60, consumedAt: date)
            meals.append(ConsumedMealData(from: meal))
        }
        
        let oldestDate = calendar.date(byAdding: .day, value: -10, to: today)!
        let oldestLog = DailyLog(date: oldestDate, calorieTarget: 2000, bodyWeight: 81.0)
        logs.append(DailyLogData(from: oldestLog))
        let oldestMeal = ConsumedMeal(name: "Test Meal", calories: 2000, protein: 150, carbs: 200, fat: 60, consumedAt: oldestDate)
        meals.append(ConsumedMealData(from: oldestMeal))
        
        let tdee = MetabolismEngine.calculateTrueTDEE(dailyLogs: logs, allMeals: meals)
        
        XCTAssertNotNil(tdee)
        XCTAssertEqual(tdee!, 2770.0, accuracy: 50.0) 
    }
}
