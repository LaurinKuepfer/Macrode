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
                LinearGradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color.green.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        weeklyCalendarView.padding(.top, 6)
                        
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
                ensureDailyLogExists(for: selectedDate)
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
                                let hitGoal = goalsMetCache[calendar.startOfDay(for: date)] == true
                                
                                VStack(spacing: 6) {
                                    Text(date.formatted(.dateTime.weekday(.short))).font(.caption2).fontWeight(isSelected ? .bold : .regular).foregroundColor(isSelected ? .primary : .secondary)
                                    ZStack {
                                        if hitGoal { Circle().stroke(Color.green, lineWidth: 2).frame(width: 38, height: 38) }
                                        Circle().fill(isSelected ? Color.primary : Color.clear).frame(width: 32, height: 32)
                                        Text(date.formatted(.dateTime.day())).font(.subheadline).fontWeight(isSelected ? .bold : .medium).foregroundColor(isSelected ? Color(UIColor.systemBackground) : (isCurrentDay ? .green : .primary))
                                    }
                                }
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                                .accessibilityElement(children: .combine)
                                .accessibilityAddTraits(.isButton)
                                .accessibilityValue(isSelected ? "Selected" : "")
                                .onTapGesture { playHaptic(); withAnimation(.spring) { selectedDate = date } }
                                .id(date)
                            }
                        }
                    }.padding(.horizontal, 24).onAppear { proxy.scrollTo(Calendar.current.startOfDay(for: Date()), anchor: .trailing) }
                }
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
            
           
            HStack(spacing: 10) {
                Button(action: { playHaptic(); viewModel.showingSmartSuggester = true }) {
                    Label("Smart Suggest", systemImage: "wand.and.stars")
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(12)
                }
                Button(action: { playHaptic(); viewModel.showingQuickAddSheet = true }) {
                    Label("Quick Add", systemImage: "bolt.fill")
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            
           
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill").foregroundColor(.cyan).font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(currentLog.waterML) ml").font(.subheadline).fontWeight(.bold)
                        Text("/ \(currentLog.waterTargetML)").font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { if currentLog.waterML >= 250 { playHaptic(); withAnimation { currentLog.waterML -= 250 } } else { withAnimation { currentLog.waterML = 0 } } }) {
                        Image(systemName: "minus.circle").font(.title3).foregroundColor(.secondary.opacity(0.8))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Menu {
                        Button(action: { addWater(250) }) { Label("Glass (250 ml)", systemImage: "cup.and.saucer") }
                        Button(action: { addWater(500) }) { Label("Flask (500 ml)", systemImage: "waterbottle") }
                        Button(action: { addWater(1000) }) { Label("Large Bottle (1L)", systemImage: "drop.fill") }
                    } label: { 
                        Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    } primaryAction: {
                        addWater(250)
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                
                fastingCompactCard
            }
            .padding(.horizontal, 24)
            
           
            frequentMealsCard
            supplementTrackerCard
            
           
            mealTimeline
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

    private var frequentMealsCard: some View {
        let meals = viewModel.frequentMeals
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
                            .padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                            .frame(width: 140)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        )
    }
    
    private var fastingCompactCard: some View {
        let lastMeal = allConsumedMeals.filter { $0.consumedAt < Date() }.max(by: { $0.consumedAt < $1.consumedAt })
        let hours = lastMeal.map { Date().timeIntervalSince($0.consumedAt) / 3600.0 } ?? 0
        
        return HStack(spacing: 8) {
            Image(systemName: "timer")
                .foregroundColor(.blue)
                .font(.body)
            VStack(alignment: .leading, spacing: 0) {
                Text("Time Since Last Meal")
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
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
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
            .padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4).padding(.horizontal, 24)
        )
    }
    
    private var mealTimeline: some View {
        let categoryOrder = ["Breakfast", "Lunch", "Dinner", "Snack"]
        let categoryIcons: [String: String] = ["Breakfast": "sunrise.fill", "Lunch": "sun.max.fill", "Dinner": "moon.stars.fill", "Snack": "leaf.fill"]
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack { Image(systemName: "clock.fill").foregroundColor(.blue); Text("Today's Timeline").font(.headline) }
            
            if selectedDateMeals.isEmpty {
                VStack { Image(systemName: "fork.knife").font(.largeTitle).foregroundColor(.secondary.opacity(0.3)); Text("Ready to fuel your day? Log your first meal!").font(.caption).foregroundColor(.secondary) }.frame(maxWidth: .infinity).padding(.vertical, 30)
            } else {
                let grouped = Dictionary(grouping: selectedDateMeals) { meal in
                    categoryOrder.contains(meal.mealCategory) ? meal.mealCategory : "Snack"
                }
                
                ForEach(categoryOrder, id: \.self) { category in
                    if let meals = grouped[category], !meals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
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
                                        viewModel.editingMeal = meal
                                    }) {
                                        MealRow(meal: meal, isNested: true)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer()
                                    
                                    Button(action: { relogMeal(meal) }) { 
                                        Image(systemName: "arrow.counterclockwise.circle.fill").font(.title3).foregroundColor(.blue.opacity(0.7)) 
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: { mealToDelete = meal }) { 
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
        .padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16)).shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4).padding(.horizontal, 24)
        .confirmationDialog("Delete Meal?", isPresented: Binding(
            get: { mealToDelete != nil },
            set: { if !$0 { mealToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let meal = mealToDelete { deleteMeal(meal) }
            }
        }
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
        LiveActivityManager.shared.updateOrStartFastingActivity(caloriesLeft: calsLeft, fastingHours: hoursSinceLastMeal)
    }
}
