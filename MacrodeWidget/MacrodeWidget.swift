import WidgetKit
import SwiftUI
import SwiftData

// 1. THE TIMELINE PROVIDER
struct Provider: TimelineProvider {
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([FoodItem.self, DailyLog.self, ConsumedMeal.self, RecipeItem.self, Supplement.self])
            // HIER DEINE EIGENE APP GROUP (exakt wie in MacrodeApp.swift):
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, groupContainer: .identifier("group.com.kuepferlaurin.macrode"))
            
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create the model container: \(error)")
        }
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), consumed: 1200, target: 2200, protein: 80, carbs: 120, fat: 40, pTarget: 150, cTarget: 250, fTarget: 70)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), consumed: 1200, target: 2200, protein: 80, carbs: 120, fat: 40, pTarget: 150, cTarget: 250, fTarget: 70)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task { @MainActor in
            let descriptor = FetchDescriptor<DailyLog>()
            let logs = (try? modelContainer.mainContext.fetch(descriptor)) ?? []
            let todayLog = logs.first(where: { Calendar.current.isDateInToday($0.date) })
            
            let mealDescriptor = FetchDescriptor<ConsumedMeal>()
            let meals = (try? modelContainer.mainContext.fetch(mealDescriptor)) ?? []
            let todayMeals = meals.filter { Calendar.current.isDateInToday($0.consumedAt) }
            
            let consumedCals = todayMeals.reduce(0) { $0 + $1.calories }
            let consumedProt = todayMeals.reduce(0) { $0 + $1.protein }
            let consumedCarbs = todayMeals.reduce(0) { $0 + $1.carbs }
            let consumedFat = todayMeals.reduce(0) { $0 + $1.fat }
            
            let sharedDefaults = UserDefaults(suiteName: "group.com.kuepferlaurin.macrode")
            let userGoalStr = sharedDefaults?.string(forKey: "userGoal") ?? "Maintain"
            let safetyFloor = sharedDefaults?.double(forKey: "safetyFloorCalories") ?? 1500.0
            
            var dynamicTarget: Double = todayLog?.calorieTarget ?? 2200
            
            // 1. Calculate TDEE
            var trueTDEE: Double? = nil
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let lookbackPeriod = calendar.date(byAdding: .day, value: -21, to: today)!
            let recentLogs = logs.filter { $0.date >= lookbackPeriod && $0.date <= today && ($0.bodyWeight ?? 0) > 0 }.sorted { $0.date < $1.date }
            if let firstLog = recentLogs.first, let lastLog = recentLogs.last, let fW = firstLog.bodyWeight, let lW = lastLog.bodyWeight, fW > 0, lW > 0 {
                let startDate = calendar.startOfDay(for: firstLog.date)
                let endDate = calendar.startOfDay(for: lastLog.date)
                let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
                if daysBetween >= 2 {
                    let weightDiff = lW - fW
                    let dailyDeficit = (weightDiff * 7700.0) / Double(daysBetween)
                    let endOfPeriod = calendar.date(byAdding: .day, value: 1, to: endDate)!
                    let mealsInPeriod = meals.filter { $0.consumedAt >= startDate && $0.consumedAt < endOfPeriod }
                    let avgCals = mealsInPeriod.reduce(0) { $0 + $1.calories } / Double(daysBetween)
                    let calc = avgCals - dailyDeficit
                    if calc > 1000 && calc < 5000 { trueTDEE = calc }
                }
            }
            
            // 2. Base Target
            var baseTarget = dynamicTarget
            if let tdee = trueTDEE {
                if userGoalStr == "Lose Weight" { baseTarget = tdee - 500 }
                else if userGoalStr == "Build Muscle" { baseTarget = tdee + 300 }
                else { baseTarget = tdee }
            }
            
            // 3. Forgiveness (Weekly Bank)
            var forgivenessCalorieAdjustment: Double = 0
            var calendarWithMonday = calendar
            calendarWithMonday.firstWeekday = 2
            let targetStartOfDay = calendarWithMonday.startOfDay(for: Date())
            if let earliestLogDate = logs.map({ $0.date }).min() {
                let earliestLogStartOfDay = calendarWithMonday.startOfDay(for: earliestLogDate)
                let startOf14Days = calendarWithMonday.date(byAdding: .day, value: -14, to: targetStartOfDay)!
                let calcStart = max(startOf14Days, earliestLogStartOfDay)
                
                if calcStart < targetStartOfDay {
                    var totalConsumed: Double = 0
                    var totalBaseTarget: Double = 0
                    var currentDate = calcStart
                    while currentDate < targetStartOfDay {
                        let nextDay = calendarWithMonday.date(byAdding: .day, value: 1, to: currentDate)!
                        let daysMeals = meals.filter { $0.consumedAt >= currentDate && $0.consumedAt < nextDay }
                        totalConsumed += daysMeals.reduce(0) { $0 + $1.calories }
                        
                        var daysBaseTarget: Double = 2200
                        if let log = logs.first(where: { calendarWithMonday.isDate($0.date, inSameDayAs: currentDate) }) {
                            daysBaseTarget = log.calorieTarget
                            if let tdee = trueTDEE { // Approximation using current TDEE
                                if userGoalStr == "Lose Weight" { daysBaseTarget = tdee - 500 }
                                else if userGoalStr == "Build Muscle" { daysBaseTarget = tdee + 300 }
                                else { daysBaseTarget = tdee }
                            }
                        }
                        totalBaseTarget += daysBaseTarget
                        currentDate = nextDay
                    }
                    
                    let bankBalance = totalConsumed - totalBaseTarget
                    if abs(bankBalance) > 200 {
                        var dailyAdj = -bankBalance / 14.0
                        if dailyAdj > 500 { dailyAdj = 500 }
                        else if dailyAdj < -500 { dailyAdj = -500 }
                        forgivenessCalorieAdjustment = dailyAdj
                    }
                }
            }
            
            dynamicTarget = max(baseTarget + forgivenessCalorieAdjustment, safetyFloor)
            
            let entry = SimpleEntry(
                date: Date(),
                consumed: consumedCals,
                target: dynamicTarget,
                protein: consumedProt,
                carbs: consumedCarbs,
                fat: consumedFat,
                pTarget: todayLog?.proteinTarget ?? 150,
                cTarget: todayLog?.carbsTarget ?? 250,
                fTarget: todayLog?.fatTarget ?? 70
            )
            
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
            completion(timeline)
        }
    }
}

// 2. DAS DATENMODELL FÜR DAS WIDGET
struct SimpleEntry: TimelineEntry {
    let date: Date
    let consumed: Double
    let target: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let pTarget: Double
    let cTarget: Double
    let fTarget: Double
}

// 3. DAS WIDGET UI
struct MacrodeWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            if family == .systemSmall {
                // SMALL WIDGET: Kalorien-Ring + Plus Button
                VStack(spacing: 8) {
                    ZStack {
                        Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: min(entry.consumed / entry.target, 1.0))
                            .stroke(entry.consumed > entry.target ? Color.red : Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 0) {
                            Text("\(abs(Int(entry.target - entry.consumed)))")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(entry.consumed > entry.target ? .red : .primary)
                            Text(entry.consumed > entry.target ? "Over" : "Left")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 80, height: 80)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Text("Add")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.green.opacity(0.15)))
                    .widgetAccentable()
                }
                .padding(8)
                .widgetURL(URL(string: "macrode://addMeal")!)
            } else if family == .systemMedium {
                // MEDIUM WIDGET: Ring + Makro-Balken
                HStack(spacing: 16) {
                    ZStack {
                        Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: min(entry.consumed / entry.target, 1.0))
                            .stroke(entry.consumed > entry.target ? Color.red : Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 0) {
                            Text("\(abs(Int(entry.target - entry.consumed)))")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(entry.consumed > entry.target ? .red : .primary)
                            Text(entry.consumed > entry.target ? "Over" : "Left")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 100, height: 100)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        WidgetMacroBar(title: "Protein", consumed: entry.protein, target: entry.pTarget, color: .red)
                        WidgetMacroBar(title: "Carbs", consumed: entry.carbs, target: entry.cTarget, color: .blue)
                        WidgetMacroBar(title: "Fat", consumed: entry.fat, target: entry.fTarget, color: .orange)
                        
                        HStack {
                            Spacer()
                            Link(destination: URL(string: "macrode://addMeal")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                    Text("Log")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.green.opacity(0.15)))
                                .widgetAccentable()
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(12)
            } else if family == .accessoryCircular {
                // LOCKSCREEN CIRCULAR: Aesthetic Gauge
                Gauge(value: entry.consumed, in: 0...entry.target) {
                    Image(systemName: "flame.fill")
                } currentValueLabel: {
                    Text("\(abs(Int(entry.target - entry.consumed)))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(entry.consumed > entry.target ? .red : .green)
            } else if family == .accessoryRectangular {
                // LOCKSCREEN RECTANGULAR: Clean and Compact
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(abs(Int(entry.target - entry.consumed)))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("kcal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("P: \(Int(entry.protein))/\(Int(entry.pTarget))").font(.system(size: 11, weight: .medium))
                        Text("C: \(Int(entry.carbs))/\(Int(entry.cTarget))").font(.system(size: 11, weight: .medium))
                        Text("F: \(Int(entry.fat))/\(Int(entry.fTarget))").font(.system(size: 11, weight: .medium))
                    }
                }
            } else if family == .accessoryInline {
                // LOCKSCREEN INLINE
                ViewThatFits {
                    Text("\(Image(systemName: "flame.fill")) \(abs(Int(entry.target - entry.consumed))) kcal \(entry.consumed > entry.target ? "over" : "left")")
                    Text("\(abs(Int(entry.target - entry.consumed))) kcal")
                }
            }
        }
        // Magischer Befehl für iOS 17+ (Löst den Background-Error)
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
}

// 4. HILFS-UI FÜR DIE BALKEN
struct WidgetMacroBar: View {
    let title: String
    let consumed: Double
    let target: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                Spacer()
                Text("\(Int(consumed)) / \(Int(target))g")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(consumed >= target ? Color.yellow : color)
                        .frame(width: min(geo.size.width * CGFloat(consumed / target), geo.size.width), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// 5. WIDGET KONFIGURATION
struct MacrodeWidget: Widget {
    let kind: String = "MacrodeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MacrodeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Macros")
        .description("Behalte deine Kalorien und Makros direkt auf dem Homescreen im Blick.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct MacrodeWidgetBundle: WidgetBundle {
    var body: some Widget {
        MacrodeWidget()
        if #available(iOS 16.1, *) {
            MacrodeLiveActivity()
        }
    }
}
