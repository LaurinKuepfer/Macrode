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
    @State private var goalsMetCache: [Date: Bool] = [:]
    
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
    
    @State private var viewModel = DashboardViewModel()
    
    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }
    
    private func updateLogsDictionary() {
        viewModel.updateLogsDictionary(dailyLogs: dailyLogs)
    }

   
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        WeeklyCalendarView(selectedDate: $selectedDate, showingHistorySheet: $showingHistorySheet, goalsMetCache: goalsMetCache, firstLaunchDate: firstLaunchDate).padding(.top, 6)
                        
                        DailyDashboardContent(selectedDate: selectedDate, currentLog: currentLog, allSupplements: allSupplements)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !hasLoadedStarterData { 
                    loadStarterDatabase()
                    hasLoadedStarterData = true 
                }
                updateLogsDictionary()
                updateGoalsMetCache()
            }
            .onChange(of: selectedDate) { _, newDate in
                ensureDailyLogExists(for: newDate)
            }
            .onChange(of: dailyLogs.count) { _, _ in
                updateLogsDictionary()
                updateGoalsMetCache()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {

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
                                Text("Energy Balance").font(.headline)
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
                                            if goalsMetCache[Calendar.current.startOfDay(for: log.date)] == true {
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
    

    private func updateGoalsMetCache() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -14, to: today)!
        let end = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let descriptor = FetchDescriptor<ConsumedMeal>(
            predicate: #Predicate { $0.consumedAt >= start && $0.consumedAt < end }
        )
        
        let recentMeals = (try? context.fetch(descriptor)) ?? []
        
        var newCache: [Date: Bool] = [:]
        for dayOffset in -14...0 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                let daysMeals = recentMeals.filter { $0.consumedAt >= dayStart && $0.consumedAt < dayEnd }
                if let log = logsDictionary[dayStart], !daysMeals.isEmpty {
                    let totalCals = daysMeals.reduce(0) { $0 + $1.calories }
                    newCache[dayStart] = totalCals <= log.calorieTarget
                } else {
                    newCache[dayStart] = false
                }
            }
        }
        self.goalsMetCache = newCache
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
    
    @State private var viewModel = DashboardViewModel()
    
    var selectedDate: Date
    var currentLog: DailyLog
    var allSupplements: [Supplement]
    
    init(selectedDate: Date, currentLog: DailyLog, allSupplements: [Supplement]) {
        self.selectedDate = selectedDate
        self.currentLog = currentLog
        self.allSupplements = allSupplements
        
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
        self._selectedDateMeals = Query(
            filter: #Predicate<ConsumedMeal> { $0.consumedAt >= start && $0.consumedAt < end },
            sort: \.consumedAt, order: .reverse
        )
        
        let lookback = Calendar.current.date(byAdding: .day, value: -60, to: start) ?? start.addingTimeInterval(-60 * 86400)
        self._allConsumedMeals = Query(filter: #Predicate<ConsumedMeal> { $0.consumedAt >= lookback })
        self._allDailyLogs = Query(filter: #Predicate<DailyLog> { $0.date >= lookback })
    }
    
    private var consumedCalories: Double { selectedDateMeals.reduce(0) { $0 + $1.calories } }
    private var consumedProtein: Double { selectedDateMeals.reduce(0) { $0 + $1.protein } }
    private var consumedCarbs: Double { selectedDateMeals.reduce(0) { $0 + $1.carbs } }
    private var consumedFat: Double { selectedDateMeals.reduce(0) { $0 + $1.fat } }
    
    private var baseTarget: Double {
        if let tdee = viewModel.cachedTDEE {
            switch userGoal {
            case .lose: return tdee - 500
            case .gain: return tdee + 300
            case .maintain: return tdee
            }
        }
        return currentLog.calorieTarget
    }
    
    @AppStorage("safetyFloorCalories") var safetyFloorCalories: Double = 1500

    private var energyBalance: BalanceEngine.BalanceResult? {
        viewModel.cachedBalance
    }
    
    private var dynamicTarget: Double {
        var target = baseTarget
        if let f = energyBalance {
            target += f.calorieAdjustment
        }
        
        return max(safetyFloorCalories, target)
    }
    
    private var activeAdjustment: Double {
        return dynamicTarget - baseTarget
    }
    
    private var dynamicProteinTarget: Double {
        if activeAdjustment > 0 {
            let proteinAdjustment = (activeAdjustment * 0.60) / 4.0
            return currentLog.proteinTarget + proteinAdjustment
        }
        return currentLog.proteinTarget
    }

    private var dynamicCarbsTarget: Double {
        if activeAdjustment > 0 {
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
           
            VStack(spacing: 6) {
                if let tdee = viewModel.cachedTDEE {
                    Label("TDEE: \(Int(tdee))", systemImage: "bolt.fill")
                        .font(.caption2).fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(6)
                }
                
                CalorieHUD(consumed: consumedCalories, target: dynamicTarget, isSocialDay: currentLog.isSocialDay)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: consumedCalories)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: dynamicTarget)
                    .overlay(alignment: .topTrailing) {
                        if let f = energyBalance, f.calorieAdjustment != 0 {
                            Label("\(Int(abs(f.calorieAdjustment))) kcal", systemImage: f.calorieAdjustment < 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2).fontWeight(.bold)
                                .foregroundColor(f.calorieAdjustment < 0 ? .purple : .green)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(f.calorieAdjustment < 0 ? Color.purple.opacity(0.1) : Color.green.opacity(0.1))
                                .cornerRadius(6)
                                .offset(x: 10, y: 10)
                        }
                    }
            }
            
           
            VStack(spacing: 12) {
                MacroBar(title: "Protein", consumed: consumedProtein, target: dynamicProteinTarget, baseColor: .red)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: consumedProtein)
                MacroBar(title: "Carbs", consumed: consumedCarbs, target: dynamicCarbsTarget, baseColor: .blue)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: consumedCarbs)
                MacroBar(title: "Fat", consumed: consumedFat, target: dynamicFatTarget, baseColor: .orange)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: consumedFat)
            }
            .padding(.horizontal, 24)
            
           
            HStack(spacing: 12) {
                Button(action: { playHaptic(); viewModel.showingSmartSuggester = true }) {
                    Label("Smart Suggest", systemImage: "wand.and.stars")
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple.opacity(0.15))
                        .cornerRadius(16)
                }
                Button(action: { playHaptic(); viewModel.showingQuickAddSheet = true }) {
                    Label("Quick Add", systemImage: "bolt.fill")
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            
           
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill").foregroundColor(.cyan).font(.title3)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(currentLog.waterML) ml").font(.subheadline).fontWeight(.bold)
                        Text("/ \(currentLog.waterTargetML)").font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { if currentLog.waterML >= 250 { playHaptic(); withAnimation { currentLog.waterML -= 250 } } else { withAnimation { currentLog.waterML = 0 } } }) {
                        Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.secondary.opacity(0.4))
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Menu {
                        Button(action: { addWater(250) }) { Label("Glass (250 ml)", systemImage: "cup.and.saucer") }
                        Button(action: { addWater(500) }) { Label("Flask (500 ml)", systemImage: "waterbottle") }
                        Button(action: { addWater(1000) }) { Label("Large Bottle (1L)", systemImage: "drop.fill") }
                    } label: { 
                        Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.blue)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    } primaryAction: {
                        addWater(250)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal, 24)
            
            FastingCompactCard(allConsumedMeals: allConsumedMeals)
                .padding(.horizontal, 24)
            
           
            FrequentMealsCard(frequentMeals: viewModel.frequentMeals)
            SupplementTrackerCard(allSupplements: allSupplements, selectedDate: selectedDate)
            
           
            MealTimeline(
                selectedDateMeals: selectedDateMeals,
                allConsumedMeals: allConsumedMeals,
                editingMeal: $viewModel.editingMeal,
                dynamicTarget: .constant(dynamicTarget),
                consumedCalories: .constant(consumedCalories)
            )
        }
        .onAppear {
            updateLiveActivity()
            recalculateEngines()
        }
        .onChange(of: consumedCalories) { _, _ in
            updateLiveActivity()
        }
        .onChange(of: allConsumedMeals.count) { _, _ in
            recalculateEngines()
        }
        .onChange(of: selectedDate) { _, _ in
            recalculateEngines()
        }
        .sheet(isPresented: $viewModel.showingSmartSuggester) {
            SmartSuggesterView(
                remProtein: max(0, dynamicProteinTarget - consumedProtein),
                remCarbs: max(0, dynamicCarbsTarget - consumedCarbs),
                remFat: max(0, dynamicFatTarget - consumedFat),
                selectedDate: selectedDate
            )
            .presentationDetents([.fraction(0.6), .large])
        }
        .sheet(item: $viewModel.editingMeal) { meal in
            EditMealView(meal: meal)
                .presentationDetents([.fraction(0.8), .large])
        }
        .sheet(isPresented: $viewModel.showingQuickAddSheet) { 
            QuickEstimateView(selectedDate: selectedDate, isRootPresented: $viewModel.showingQuickAddSheet).presentationDetents([.fraction(0.5), .large]) 
        }
    }

    private func recalculateEngines() {
        viewModel.recalculateEngines(allDailyLogs: allDailyLogs, allConsumedMeals: allConsumedMeals, userGoal: userGoal, selectedDate: selectedDate)
        viewModel.updateFrequentMeals(allConsumedMeals: allConsumedMeals)
    }


    
    private func playHaptic() { HapticManager.shared.impact(.light) }
    
    private func addWater(_ amount: Int) { playHaptic(); withAnimation { currentLog.waterML += amount }; try? context.save(); HealthKitManager.shared.saveWater(amountML: Double(amount), date: Date()); Task { WidgetCenter.shared.reloadAllTimelines() } }
    
    private func updateLiveActivity() {
        let pastMeals = allConsumedMeals.filter { $0.consumedAt < Date() }.sorted { $0.consumedAt > $1.consumedAt }
        let hoursSinceLastMeal = pastMeals.first.map { Date().timeIntervalSince($0.consumedAt) / 3600.0 } ?? 0
        let calsLeft = max(0, Int(dynamicTarget - consumedCalories))
        LiveActivityManager.shared.updateOrStartFastingActivity(caloriesLeft: calsLeft, fastingHours: hoursSinceLastMeal)
    }
}
