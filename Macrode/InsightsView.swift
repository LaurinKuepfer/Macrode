import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ConsumedMeal.consumedAt, order: .reverse) private var allMeals: [ConsumedMeal]
    @Query private var dailyLogs: [DailyLog]
    
    @Binding var selectedDate: Date
    
    @State private var showingWeightAlert = false
    @State private var weightInput: String = ""

    private var currentLog: DailyLog? {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        return dailyLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) })
    }
    
    private var logsDictionary: [Date: DailyLog] {
        var dict = [Date: DailyLog]()
        for log in dailyLogs { dict[Calendar.current.startOfDay(for: log.date)] = log }
        return dict
    }
    
   
    
    private var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())
        
        var dict = [Date: DailyLog]()
        for log in dailyLogs { dict[calendar.startOfDay(for: log.date)] = log }
        
        var dailyCalories = [Date: Double]()
        for meal in allMeals {
            let day = calendar.startOfDay(for: meal.consumedAt)
            dailyCalories[day, default: 0] += meal.calories
        }
        
        func goalMet(on date: Date) -> Bool {
            let start = calendar.startOfDay(for: date)
            guard let log = dict[start], let calories = dailyCalories[start] else { return false }
            return calories > 0 && calories <= log.calorieTarget
        }
        
        if goalMet(on: checkDate) { streak += 1 }
        
        checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        for _ in 0..<100 {
            if goalMet(on: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else { break }
        }
        return streak
    }
    
    private var trueMetabolism: Double? {
        MetabolismEngine.calculateTrueTDEE(dailyLogs: dailyLogs, allMeals: allMeals)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    if currentStreak > 0 { streakBanner }
                    
                    if let tdee = trueMetabolism { metabolismInsightCard(tdee: tdee) }
                    
                    weeklyCalorieChartCard
                    
                    weeklyMacroPieChartCard
                    
                    weightTrackerCard
                }
                .padding(.vertical, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Insights")
            .onAppear {
                ReviewManager.shared.checkAndPromptReview(currentStreak: currentStreak)
            }
        }
    }
    
   
    private var streakBanner: some View {
        HStack {
            Image(systemName: "flame.fill").foregroundColor(.orange)
            Text("\(currentStreak) Day Streak").font(.headline).fontWeight(.bold).foregroundColor(.orange)
            Spacer()
            Text("Perfect Days!").font(.subheadline).foregroundColor(.secondary)
        }
        .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2).padding(.horizontal, 24)
    }
    
    private func metabolismInsightCard(tdee: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Image(systemName: "brain.head.profile").foregroundColor(.purple); Text("Smart Insights").font(.headline) }
            Text("Based on your last logs, your True Metabolism (TDEE) is approx **\(Int(tdee)) kcal** per day.")
                .font(.subheadline).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2).padding(.horizontal, 24)
    }
    
    private var weeklyCalorieChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Image(systemName: "chart.bar.fill").foregroundColor(.orange); Text("Weekly Calories").font(.headline) }
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: selectedDate)
            let past7Days = (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
            
            Chart {
                ForEach(past7Days, id: \.self) { date in
                    let dayStart = calendar.startOfDay(for: date)
                    let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                    let meals = allMeals.filter { $0.consumedAt >= dayStart && $0.consumedAt < dayEnd }
                    let cals = meals.reduce(0) { $0 + $1.calories }
                    let target = logsDictionary[dayStart]?.calorieTarget ?? 2000
                    
                    BarMark(
                        x: .value("Day", date, unit: .day),
                        y: .value("Calories", cals)
                    )
                    .foregroundStyle(cals > target ? Color.red.gradient : Color.green.gradient)
                    
                    RuleMark(y: .value("Target", target))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 180)
            .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
        }
        .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2).padding(.horizontal, 24)
    }
    
    private var weeklyMacroPieChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Image(systemName: "chart.pie.fill").foregroundColor(.pink); Text("Weekly Macro Split").font(.headline) }
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: selectedDate)
            let past7DaysStart = calendar.date(byAdding: .day, value: -6, to: today)!
            
            let recentMeals = allMeals.filter { $0.consumedAt >= past7DaysStart }
            let totalPro = recentMeals.reduce(0) { $0 + $1.protein }
            let totalCarb = recentMeals.reduce(0) { $0 + $1.carbs }
            let totalFat = recentMeals.reduce(0) { $0 + $1.fat }
            let totalMacros = totalPro + totalCarb + totalFat
            
            if totalMacros > 0 {
                Chart {
                    SectorMark(angle: .value("Protein", totalPro), innerRadius: .ratio(0.5), angularInset: 1.5)
                        .foregroundStyle(Color.red.gradient)
                    SectorMark(angle: .value("Carbs", totalCarb), innerRadius: .ratio(0.5), angularInset: 1.5)
                        .foregroundStyle(Color.blue.gradient)
                    SectorMark(angle: .value("Fat", totalFat), innerRadius: .ratio(0.5), angularInset: 1.5)
                        .foregroundStyle(Color.orange.gradient)
                }
                .frame(height: 180)
                HStack(spacing: 20) {
                    Label("\(Int((totalPro/totalMacros)*100))%", systemImage: "circle.fill").foregroundColor(.red)
                    Label("\(Int((totalCarb/totalMacros)*100))%", systemImage: "circle.fill").foregroundColor(.blue)
                    Label("\(Int((totalFat/totalMacros)*100))%", systemImage: "circle.fill").foregroundColor(.orange)
                }
                .font(.caption).fontWeight(.bold).frame(maxWidth: .infinity)
            } else {
                Text("Not enough data.").foregroundColor(.secondary)
            }
        }
        .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2).padding(.horizontal, 24)
    }
    
    private var weightTrackerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "scalemass.fill").foregroundColor(.purple)
                Text("Body Weight").font(.headline)
                Spacer()
                Button(action: {
                    HapticManager.shared.impact(.light)
                    weightInput = currentLog?.bodyWeight.map { String($0) } ?? ""
                    showingWeightAlert = true
                }) {
                    Text(currentLog?.bodyWeight.map { "\($0, specifier: "%.1f") kg" } ?? "Log Weight")
                        .font(.subheadline).fontWeight(.bold).foregroundColor(currentLog?.bodyWeight != nil ? .primary : .white)
                        .padding(.horizontal, 12).padding(.vertical, 6).background(currentLog?.bodyWeight != nil ? Color.secondary.opacity(0.2) : Color.purple).cornerRadius(8)
                }
            }
            let logsWithWeight = dailyLogs.filter { $0.bodyWeight != nil }.sorted(by: { $0.date < $1.date })
            if logsWithWeight.count >= 2 {
                Chart {
                    ForEach(logsWithWeight) { log in
                        if let weight = log.bodyWeight {
                            AreaMark(x: .value("Date", log.date), y: .value("Weight", weight)).interpolationMethod(.monotone).foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.4), Color.clear]), startPoint: .top, endPoint: .bottom))
                            LineMark(x: .value("Date", log.date), y: .value("Weight", weight)).interpolationMethod(.monotone).foregroundStyle(Color.purple.gradient)
                            PointMark(x: .value("Date", log.date), y: .value("Weight", weight)).foregroundStyle(Color.purple)
                        }
                    }
                }
                .frame(height: 120).chartYScale(domain: .automatic(includesZero: false)).chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisTick(); AxisValueLabel(format: .dateTime.weekday(), centered: true) } }
            } else {
                VStack { Image(systemName: "chart.xyaxis.line").font(.largeTitle).foregroundColor(.secondary.opacity(0.3)); Text("Log your weight for a few days to see your trend.").font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center) }
                .frame(maxWidth: .infinity).frame(height: 100)
            }
        }
        .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2).padding(.horizontal, 24)
        .alert("Log Body Weight", isPresented: $showingWeightAlert) {
            TextField("Weight (e.g. 75.5)", text: $weightInput).keyboardType(.decimalPad)
            Button("Save") {
                if let weight = Double(weightInput.replacingOccurrences(of: ",", with: ".")) {
                    HapticManager.shared.impact(.light)
                    withAnimation { 
                        currentLog?.bodyWeight = weight
                        let newWaterTarget = Int((weight / 20.0) * 1000)
                        currentLog?.waterTargetML = newWaterTarget
                    }
                    try? context.save()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("Enter your weight for \(selectedDate.formatted(.dateTime.month().day())).") }
    }
    

}
