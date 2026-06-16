import SwiftUI
import SwiftData
import WidgetKit

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var dailyLogs: [DailyLog]
    @Query private var allSupplements: [Supplement]

    @AppStorage("hasLoadedStarterData") private var hasLoadedStarterData: Bool = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("firstLaunchDate") private var firstLaunchDate: Double = Date().timeIntervalSince1970
    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial: Bool = false

    @Binding var selectedDate: Date
    @Binding var selectedTab: Int
    
    @State private var showingGoalsSheet = false
    @State private var showingHistorySheet = false
    @State private var showingQuickAddSheet = false
    
    private var currentLog: DailyLog {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        if let log = dailyLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }) {
            return log
        } else {
            let previousLogs = dailyLogs.filter { $0.date < startOfDay }.sorted { $0.date > $1.date }
            if let lastLog = previousLogs.first {
                return DailyLog(date: startOfDay, calorieTarget: lastLog.calorieTarget, proteinTarget: lastLog.proteinTarget, carbsTarget: lastLog.carbsTarget, fatTarget: lastLog.fatTarget, waterTargetML: lastLog.waterTargetML, bodyWeight: lastLog.bodyWeight)
            } else {
                return DailyLog(date: startOfDay)
            }
        }
    }
    
    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }
    
    private var logsDictionary: [Date: DailyLog] {
        var dict = [Date: DailyLog]()
        for log in dailyLogs { dict[Calendar.current.startOfDay(for: log.date)] = log }
        return dict
    }

    // MARK: - Main Body
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        weeklyCalendarView.padding(.top, 6)
                        
                        DailyDashboardContent(selectedDate: selectedDate, currentLog: currentLog, allSupplements: allSupplements)
                    }
                    .padding(.bottom, 30)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !hasLoadedStarterData { 
                    loadStarterDatabase()
                    hasLoadedStarterData = true 
                }
                ensureDailyLogExists(for: selectedDate)
            }
            .onChange(of: selectedDate) { _, newDate in
                ensureDailyLogExists(for: newDate)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { 
                            playHaptic()
                            selectedTab = 2 
                        }) {
                            Image(systemName: "plus.circle.fill").foregroundColor(.green)
                        }
                        
                        Button(action: { 
                            playHaptic()
                            showingGoalsSheet = true 
                        }) {
                            Image(systemName: "target").foregroundColor(.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: Binding(get: { !hasCompletedTutorial && hasSeenOnboarding }, set: { _ in })) {
                VStack(spacing: 30) {
                    Text("Quick Guide").font(.largeTitle).fontWeight(.bold).padding(.top, 40)
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 16) {
                            Image(systemName: "book.pages.fill").font(.largeTitle).foregroundColor(.green).frame(width: 45)
                            VStack(alignment: .leading) { 
                                Text("Log Meals").font(.headline)
                                Text("Use the Library tab below to log foods and recipes.").font(.subheadline).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        HStack(spacing: 16) {
                            Image(systemName: "target").font(.largeTitle).foregroundColor(.primary).frame(width: 45)
                            VStack(alignment: .leading) { 
                                Text("Adjust Your Goals").font(.headline)
                                Text("Tap the target icon anytime to adjust macros and supplements.").font(.subheadline).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        HStack(spacing: 16) {
                            Image(systemName: "banknote.fill").font(.largeTitle).foregroundColor(.orange).frame(width: 45)
                            VStack(alignment: .leading) { 
                                Text("The Weekly Bank").font(.headline)
                                Text("Your daily targets adapt automatically to smooth out calorie spikes.").font(.subheadline).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        HStack(spacing: 16) {
                            Image(systemName: "chart.xyaxis.line").font(.largeTitle).foregroundColor(.purple).frame(width: 45)
                            VStack(alignment: .leading) { 
                                Text("Check Insights").font(.headline)
                                Text("Use the Insights tab to see your weight, streak, and metabolism.").font(.subheadline).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }.padding(.horizontal, 20)
                    Spacer()
                    Button(action: { 
                        playHaptic()
                        hasCompletedTutorial = true 
                    }) {
                        Text("Got it!").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(Color.blue).cornerRadius(16)
                    }.padding(.horizontal, 30).padding(.bottom, 30)
                }
                .presentationDetents([.fraction(0.7)]).interactiveDismissDisabled()
            }
            .sheet(isPresented: $showingGoalsSheet) { 
                EditGoalsView(dailyLog: currentLog).presentationDetents([.fraction(0.8)]) 
            }
            .sheet(isPresented: $showingQuickAddSheet) { 
                QuickEstimateView(selectedDate: selectedDate, isRootPresented: $showingQuickAddSheet).presentationDetents([.fraction(0.5), .large]) 
            }
            .sheet(isPresented: $showingHistorySheet) {
                NavigationStack {
                    let groupedLogs = Dictionary(grouping: dailyLogs.sorted(by: { $0.date > $1.date })) { log -> String in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMMM yyyy"
                        return formatter.string(from: log.date)
                    }
                    
                    let sortedMonths = groupedLogs.keys.sorted { month1, month2 in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMMM yyyy"
                        guard let d1 = formatter.date(from: month1), let d2 = formatter.date(from: month2) else { return false }
                        return d1 > d2
                    }
                    
                    List {
                        ForEach(sortedMonths, id: \.self) { month in
                            Section(header: Text(month).font(.headline).foregroundColor(.primary)) {
                                ForEach(groupedLogs[month] ?? []) { log in
                                    Button(action: {
                                        playHaptic()
                                        withAnimation(.spring) {
                                            selectedDate = log.date
                                        }
                                        showingHistorySheet = false
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(log.date.formatted(.dateTime.weekday(.wide).day()))
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Text("\(Int(log.calorieTarget)) kcal Goal")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            if checkIfGoalMet(for: log.date) {
                                                Image(systemName: "flame.fill")
                                                    .foregroundColor(.orange)
                                            }
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Your History")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Close") { showingHistorySheet = false }
                        }
                    }
                }
                .presentationDetents([.fraction(0.85), .large])
            }
            .fullScreenCover(isPresented: Binding(get: { !hasSeenOnboarding }, set: { _ in })) { 
                OnboardingView() 
            }
        }
    }
    
    // MARK: - UI Components
    private var weeklyCalendarView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(selectedDate.formatted(.dateTime.month(.wide).year())).font(.headline).foregroundColor(.primary)
                Spacer()
                Button(action: { playHaptic(); showingHistorySheet = true }) {
                    HStack(spacing: 4) { Text("History"); Image(systemName: "calendar") }.font(.subheadline).foregroundColor(.green)
                }
            }
            .padding(.horizontal, 24)
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 12) {
                        let calendar = Calendar.current
                        let today = calendar.startOfDay(for: Date())
                        let maxDaysToShow = 14
                        let firstLaunch = calendar.startOfDay(for: Date(timeIntervalSince1970: firstLaunchDate))
                        
                        ForEach(-maxDaysToShow...0, id: \.self) { dayOffset in
                            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today), date >= firstLaunch {
                                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                                let isCurrentDay = calendar.isDateInToday(date)
                                let hitGoal = checkIfGoalMet(for: date)
                                
                                VStack(spacing: 6) {
                                    Text(date.formatted(.dateTime.weekday(.short))).font(.caption2).fontWeight(isSelected ? .bold : .regular).foregroundColor(isSelected ? .primary : .secondary)
                                    ZStack {
                                        if hitGoal { Circle().stroke(Color.green, lineWidth: 2).frame(width: 38, height: 38) }
                                        Circle().fill(isSelected ? Color.primary : Color.clear).frame(width: 32, height: 32)
                                        Text(date.formatted(.dateTime.day())).font(.subheadline).fontWeight(isSelected ? .bold : .medium).foregroundColor(isSelected ? Color(UIColor.systemBackground) : (isCurrentDay ? .green : .primary))
                                    }
                                }.id(date).onTapGesture { playHaptic(); withAnimation(.spring) { selectedDate = date } }
                            }
                        }
                    }.padding(.horizontal, 24).onAppear { proxy.scrollTo(Calendar.current.startOfDay(for: Date()), anchor: .trailing) }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func checkIfGoalMet(for date: Date) -> Bool {
        let calendar = Calendar.current
        guard let log = logsDictionary[calendar.startOfDay(for: date)] else { return false }
        
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let descriptor = FetchDescriptor<ConsumedMeal>(
            predicate: #Predicate { $0.consumedAt >= start && $0.consumedAt < end }
        )
        
        let meals = (try? context.fetch(descriptor)) ?? []
        let totalCals = meals.reduce(0) { $0 + $1.calories }
        
        return !meals.isEmpty && totalCals <= log.calorieTarget
    }

    private func ensureDailyLogExists(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        if !dailyLogs.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }) {
            let previousLogs = dailyLogs.filter { $0.date < startOfDay }.sorted { $0.date > $1.date }
            if let lastLog = previousLogs.first {
                let newLog = DailyLog(date: startOfDay, calorieTarget: lastLog.calorieTarget, proteinTarget: lastLog.proteinTarget, carbsTarget: lastLog.carbsTarget, fatTarget: lastLog.fatTarget, waterTargetML: lastLog.waterTargetML, bodyWeight: lastLog.bodyWeight)
                context.insert(newLog)
            } else {
                let newLog = DailyLog(date: startOfDay)
                context.insert(newLog)
            }
            try? context.save()
        }
    }

    private func loadStarterDatabase() {
        for item in StarterDatabase.foods { context.insert(FoodItem(name: item.name, calories: item.calories, protein: item.protein, carbs: item.carbs, fat: item.fat, category: item.category)) }
        for recipe in StarterDatabase.recipes { context.insert(RecipeItem(name: recipe.name, calories: recipe.calories, protein: recipe.protein, carbs: recipe.carbs, fat: recipe.fat, instructions: recipe.instructions, category: recipe.category, prepTimeMinutes: recipe.prepTimeMinutes, difficulty: recipe.difficulty, systemImage: recipe.systemImage)) }
    }

    private func playHaptic() { HapticManager.shared.impact(.light) }
}

struct DailyDashboardContent: View {
    @Environment(\.modelContext) private var context
    @Query private var selectedDateMeals: [ConsumedMeal]
    @Query private var allDailyLogs: [DailyLog]
    @Query private var allConsumedMeals: [ConsumedMeal]
    
    @AppStorage("userGoal") private var userGoal: GoalType = .maintain
    @State private var showingMacroTetris = false
    @State private var editingMeal: ConsumedMeal? = nil
    
    var selectedDate: Date
    var currentLog: DailyLog
    var allSupplements: [Supplement]
    
    init(selectedDate: Date, currentLog: DailyLog, allSupplements: [Supplement]) {
        self.selectedDate = selectedDate
        self.currentLog = currentLog
        self.allSupplements = allSupplements
        
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        self._selectedDateMeals = Query(
            filter: #Predicate<ConsumedMeal> { $0.consumedAt >= start && $0.consumedAt < end },
            sort: \.consumedAt, order: .reverse
        )
    }
    
    private var consumedCalories: Double { selectedDateMeals.reduce(0) { $0 + $1.calories } }
    private var consumedProtein: Double { selectedDateMeals.reduce(0) { $0 + $1.protein } }
    private var consumedCarbs: Double { selectedDateMeals.reduce(0) { $0 + $1.carbs } }
    private var consumedFat: Double { selectedDateMeals.reduce(0) { $0 + $1.fat } }
    
    private var trueTDEE: Double? {
        MetabolismEngine.calculateTrueTDEE(dailyLogs: allDailyLogs, allMeals: allConsumedMeals)
    }
    
    private var baseTarget: Double {
        if let tdee = trueTDEE {
            switch userGoal {
            case .lose: return tdee - 500
            case .gain: return tdee + 300
            case .maintain: return tdee
            }
        }
        return currentLog.calorieTarget
    }
    
    @AppStorage("safetyFloorCalories") var safetyFloorCalories: Double = 1500

    private var forgiveness: ForgivenessEngine.ForgivenessResult? {
        ForgivenessEngine.calculateForgiveness(for: selectedDate, allLogs: allDailyLogs, allMeals: allConsumedMeals, userGoal: userGoal)
    }
    
    private var dynamicTarget: Double {
        var target = baseTarget
        if let f = forgiveness {
            target += f.calorieAdjustment
        }
        
        return max(safetyFloorCalories, target)
    }
    
    private var activeAdjustment: Double {
        return dynamicTarget - baseTarget
    }
    
    private var dynamicProteinTarget: Double {
        if activeAdjustment > 0 {
            // Give 60% of extra calories to protein
            let proteinAdjustment = (activeAdjustment * 0.60) / 4.0
            return currentLog.proteinTarget + proteinAdjustment
        }
        return currentLog.proteinTarget
    }

    private var dynamicCarbsTarget: Double {
        if activeAdjustment > 0 {
            // Give 20% of extra calories to carbs
            let carbAdjustment = (activeAdjustment * 0.20) / 4.0
            return max(30, currentLog.carbsTarget + carbAdjustment)
        } else if activeAdjustment < 0 {
            let carbAdjustment = (activeAdjustment * 0.50) / 4.0
            return max(30, currentLog.carbsTarget + carbAdjustment)
        }
        return currentLog.carbsTarget
    }
    
    private var dynamicFatTarget: Double {
        if activeAdjustment > 0 {
            // Give 20% of extra calories to fat
            let fatAdjustment = (activeAdjustment * 0.20) / 9.0
            return max(20, currentLog.fatTarget + fatAdjustment)
        } else if activeAdjustment < 0 {
            let fatAdjustment = (activeAdjustment * 0.50) / 9.0
            return max(20, currentLog.fatTarget + fatAdjustment)
        }
        return currentLog.fatTarget
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // MARK: Hero Section — Calorie Ring + Smart Badges
            VStack(spacing: 6) {
                // Compact inline badges (TDEE + Bank adjustment)
                HStack(spacing: 8) {
                    if let tdee = trueTDEE {
                        Label("TDEE: \(Int(tdee))", systemImage: "bolt.fill")
                            .font(.caption2).fontWeight(.bold)
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(6)
                    }
                    if let f = forgiveness, f.calorieAdjustment != 0 {
                        Label("\(f.calorieAdjustment > 0 ? "+" : "")\(Int(f.calorieAdjustment))", systemImage: "banknote.fill")
                            .font(.caption2).fontWeight(.bold)
                            .foregroundColor(f.calorieAdjustment < 0 ? .red : .green)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(f.calorieAdjustment < 0 ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                CalorieHUD(consumed: consumedCalories, target: dynamicTarget, isSocialDay: currentLog.isSocialDay)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: consumedCalories)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: dynamicTarget)
            }
            
            // MARK: Macro Bars
            VStack(spacing: 12) {
                MacroBar(title: "Protein", consumed: consumedProtein, target: dynamicProteinTarget, baseColor: .red)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: consumedProtein)
                MacroBar(title: "Carbs", consumed: consumedCarbs, target: dynamicCarbsTarget, baseColor: .blue)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: consumedCarbs)
                MacroBar(title: "Fat", consumed: consumedFat, target: dynamicFatTarget, baseColor: .orange)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: consumedFat)
            }
            .padding(.horizontal, 24)
            
            // MARK: Compact Action Row
            HStack(spacing: 10) {
                Button(action: { playHaptic(); showingMacroTetris = true }) {
                    Label("Macro Tetris", systemImage: "puzzlepiece.extension.fill")
                        .font(.caption).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                Button(action: { playHaptic(); showingQuickAddSheet = true }) {
                    Label("Quick Add", systemImage: "bolt.fill")
                        .font(.caption).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(LinearGradient(gradient: Gradient(colors: [.green, .mint]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            
            // MARK: Quick Glance Row — Water + Fasting side by side
            HStack(spacing: 12) {
                // Water compact
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill").foregroundColor(.cyan).font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(currentLog.waterML) ml").font(.subheadline).fontWeight(.bold)
                        Text("/ \(currentLog.waterTargetML)").font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { if currentLog.waterML >= 250 { playHaptic(); withAnimation { currentLog.waterML -= 250 } } else { withAnimation { currentLog.waterML = 0 } } }) {
                        Image(systemName: "minus.circle").font(.body).foregroundColor(.secondary.opacity(0.5))
                    }.buttonStyle(.plain)
                    Menu {
                        Button(action: { addWater(250) }) { Label("Glass (250 ml)", systemImage: "cup.and.saucer") }
                        Button(action: { addWater(500) }) { Label("Flask (500 ml)", systemImage: "waterbottle") }
                        Button(action: { addWater(1000) }) { Label("Large Bottle (1L)", systemImage: "drop.fill") }
                    } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.blue) }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                
                // Fasting compact
                fastingCompactCard
            }
            .padding(.horizontal, 24)
            
            // MARK: Contextual Cards (only shown when relevant)
            frequentMealsCard
            supplementTrackerCard
            
            // MARK: Meal Timeline
            mealTimeline
        }
        .onAppear {
            updateLiveActivity()
        }
        .onChange(of: consumedCalories) { _, _ in
            updateLiveActivity()
        }
        .sheet(isPresented: $showingMacroTetris) {
            MacroTetrisView(
                remProtein: max(0, dynamicProteinTarget - consumedProtein),
                remCarbs: max(0, dynamicCarbsTarget - consumedCarbs),
                remFat: max(0, dynamicFatTarget - consumedFat),
                selectedDate: selectedDate
            )
            .presentationDetents([.fraction(0.6), .large])
        }
        .sheet(item: $editingMeal) { meal in
            EditMealView(meal: meal)
                .presentationDetents([.fraction(0.8), .large])
        }
    }


    private var frequentMeals: [ConsumedMeal] {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let startOfToday = calendar.startOfDay(for: now)
        
        // Find names of meals already consumed today so we don't suggest them again
        let todayMealNames = Set(allConsumedMeals.filter { $0.consumedAt >= startOfToday }.map { $0.name })
        
        let recentMeals = allConsumedMeals.filter {
            // Exclude anything logged today
            guard $0.consumedAt < startOfToday else { return false }
            
            let daysAgo = calendar.dateComponents([.day], from: $0.consumedAt, to: now).day ?? 0
            guard daysAgo <= 30 else { return false }
            
            let mealHour = calendar.component(.hour, from: $0.consumedAt)
            let diff = abs(mealHour - currentHour)
            return diff <= 2 || diff >= 22
        }
        
        let grouped = Dictionary(grouping: recentMeals, by: { $0.name })
        // Only consider it a habit if they ate it at least twice, and haven't eaten it yet today
        let frequent = grouped.filter { !todayMealNames.contains($0.key) && $0.value.count >= 2 }
        
        let sorted = frequent.sorted { $0.value.count > $1.value.count }
        return sorted.prefix(3).compactMap { $0.value.first }
    }
    
    private var frequentMealsCard: some View {
        let meals = frequentMeals
        if meals.isEmpty { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                HStack { Image(systemName: "sparkles").foregroundColor(.yellow); Text("Usually at this time...").font(.headline) }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(meals, id: \.id) { (meal: ConsumedMeal) in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(meal.name).font(.subheadline).fontWeight(.bold).lineLimit(1)
                                Text("\(Int(meal.calories)) kcal").font(.caption).foregroundColor(.green)
                                Button(action: {
                                    HapticManager.shared.notification(.success)
                                    let now = Date()
                                    let newMeal = ConsumedMeal(name: meal.name, calories: meal.calories, protein: meal.protein, carbs: meal.carbs, fat: meal.fat, weightGrams: meal.weightGrams, consumedAt: now, mealCategory: autoMealCategory(for: now), fiber: meal.fiber, sugar: meal.sugar, saturatedFat: meal.saturatedFat, sodium: meal.sodium)
                                    context.insert(newMeal)
                                    try? context.save()
                                    HealthKitManager.shared.saveMeal(name: meal.name, calories: meal.calories, protein: meal.protein, carbs: meal.carbs, fat: meal.fat, date: now)
                                    Task { WidgetCenter.shared.reloadAllTimelines() }
                                }) {
                                    Text("Log").font(.caption).fontWeight(.bold).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 6).background(Color.green).cornerRadius(12)
                                }
                            }
                            .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .frame(width: 140)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        )
    }
    
    private var fastingCompactCard: some View {
        let pastMeals = allConsumedMeals.filter { $0.consumedAt < Date() }.sorted { $0.consumedAt > $1.consumedAt }
        let lastMeal = pastMeals.first
        let hours = lastMeal.map { Date().timeIntervalSince($0.consumedAt) / 3600.0 } ?? 0
        let isFasting = hours >= 12
        
        return HStack(spacing: 8) {
            Image(systemName: isFasting ? "flame.fill" : "timer")
                .foregroundColor(isFasting ? .orange : .blue)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(isFasting ? "Fasting" : "Last Meal")
                    .font(.caption2).foregroundColor(.secondary)
                if lastMeal != nil {
                    Text(String(format: "%.1fh", hours))
                        .font(.subheadline).fontWeight(.bold)
                } else {
                    Text("—").font(.subheadline).fontWeight(.bold)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(isFasting ? Color.purple.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }

    private var supplementTrackerCard: some View {
        let currentDayOfWeek = Calendar.current.component(.weekday, from: selectedDate)
        let todaysSupplements = allSupplements.filter { supp in
            let days = supp.scheduledDays.split(separator: ",").compactMap { Int($0) }
            return days.contains(currentDayOfWeek)
        }
        
        if todaysSupplements.isEmpty { return AnyView(EmptyView()) }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let dateString = formatter.string(from: selectedDate)
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        
        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                HStack { Image(systemName: "pills.fill").foregroundColor(.pink); Text("Supplements").font(.headline) }
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(todaysSupplements) { supp in
                        let isTaken = supp.datesTaken.contains(dateString)
                        
                        Button(action: {
                            playHaptic()
                            withAnimation(.spring) {
                                if isTaken { supp.datesTaken.removeAll(where: { $0 == dateString }) }
                                else { supp.datesTaken.append(dateString) }
                                try? context.save()
                            }
                        }) {
                            HStack {
                                Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                                Text(supp.name).lineLimit(1)
                            }
                            .font(.subheadline).fontWeight(.semibold).foregroundColor(isTaken ? .white : .primary)
                            .padding(.vertical, 12).frame(maxWidth: .infinity)
                            .background(isTaken ? Color.pink : Color.secondary.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2).padding(.horizontal, 24)
        )
    }
    
    private var mealTimeline: some View {
        let categoryOrder = ["Breakfast", "Lunch", "Dinner", "Snack"]
        let categoryIcons: [String: String] = ["Breakfast": "sunrise.fill", "Lunch": "sun.max.fill", "Dinner": "moon.stars.fill", "Snack": "leaf.fill"]
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack { Image(systemName: "clock.fill").foregroundColor(.blue); Text("Today's Timeline").font(.headline) }
            
            if selectedDateMeals.isEmpty {
                VStack { Image(systemName: "fork.knife").font(.largeTitle).foregroundColor(.secondary.opacity(0.3)); Text("No meals logged yet.").font(.caption).foregroundColor(.secondary) }.frame(maxWidth: .infinity).padding(.vertical, 30)
            } else {
                let grouped = Dictionary(grouping: selectedDateMeals) { meal in
                    categoryOrder.contains(meal.mealCategory) ? meal.mealCategory : "Snack"
                }
                
                ForEach(categoryOrder, id: \.self) { category in
                    if let meals = grouped[category], !meals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            // Category header
                            HStack(spacing: 6) {
                                Image(systemName: categoryIcons[category] ?? "fork.knife")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(category)
                                    .font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                                    .textCase(.uppercase)
                            }
                            .padding(.top, 4)
                            
                            ForEach(meals.sorted { $0.consumedAt < $1.consumedAt }) { meal in
                                HStack(spacing: 8) { 
                                    Button(action: {
                                        playHaptic()
                                        editingMeal = meal
                                    }) {
                                        MealRow(meal: meal)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer()
                                    
                                    // Re-log button
                                    Button(action: { relogMeal(meal) }) { 
                                        Image(systemName: "arrow.counterclockwise.circle.fill").font(.title3).foregroundColor(.blue.opacity(0.7)) 
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: { deleteMeal(meal) }) { 
                                        Image(systemName: "trash.circle.fill").font(.title3).foregroundColor(.red.opacity(0.6)) 
                                    }
                                    .buttonStyle(.plain) 
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
        }
        .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2).padding(.horizontal, 24)
    }
    
    private func playHaptic() { HapticManager.shared.impact(.light) }
    
    private func addWater(_ amount: Int) { playHaptic(); withAnimation { currentLog.waterML += amount }; try? context.save(); HealthKitManager.shared.saveWater(amountML: Double(amount), date: Date()); Task { WidgetCenter.shared.reloadAllTimelines() } }
    
    private func relogMeal(_ meal: ConsumedMeal) {
        playHaptic()
        let hour = Calendar.current.component(.hour, from: Date())
        let autoCategory: String = hour < 10 ? "Breakfast" : (hour < 14 ? "Lunch" : (hour < 17 ? "Snack" : "Dinner"))
        
        let copy = ConsumedMeal(
            name: meal.name,
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat,
            weightGrams: meal.weightGrams,
            consumedAt: Date(),
            mealCategory: autoCategory,
            fiber: meal.fiber,
            sugar: meal.sugar,
            saturatedFat: meal.saturatedFat,
            sodium: meal.sodium
        )
        withAnimation { context.insert(copy) }
        try? context.save()
        Task { WidgetCenter.shared.reloadAllTimelines() }
        updateLiveActivity()
    }
    
    private func deleteMeal(_ meal: ConsumedMeal) { 
        playHaptic()
        withAnimation { context.delete(meal) }
        try? context.save()
        Task { WidgetCenter.shared.reloadAllTimelines() }
        updateLiveActivity()
    }
    
    private func updateLiveActivity() {
        let pastMeals = allConsumedMeals.filter { $0.consumedAt < Date() }.sorted { $0.consumedAt > $1.consumedAt }
        let hoursSinceLastMeal = pastMeals.first.map { Date().timeIntervalSince($0.consumedAt) / 3600.0 } ?? 0
        let calsLeft = max(0, Int(dynamicTarget - consumedCalories))
        LiveActivityManager.shared.startFastingActivity(caloriesLeft: calsLeft, fastingHours: hoursSinceLastMeal)
    }
}
