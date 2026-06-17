import SwiftUI
import SwiftData
import WidgetKit

struct SmartSuggesterView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Query private var foodLibrary: [FoodItem]
    @Query private var pastMeals: [ConsumedMeal]
    
    var remProtein: Double
    var remCarbs: Double
    var remFat: Double
    var selectedDate: Date
    
    @State private var suggestion: [FoodPortion] = []
    @State private var isCalculating = true
    
    struct FoodPortion: Identifiable {
        let id = UUID()
        let food: FoodItem
        let grams: Double
        
        var calories: Double { food.calories * (grams / 100.0) }
        var protein: Double { food.protein * (grams / 100.0) }
        var carbs: Double { food.carbs * (grams / 100.0) }
        var fat: Double { food.fat * (grams / 100.0) }
    }
    
    struct FoodData: Sendable {
        let id: UUID
        let name: String
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        
        init(from item: FoodItem) {
            self.id = item.id
            self.name = item.name
            self.calories = item.calories
            self.protein = item.protein
            self.carbs = item.carbs
            self.fat = item.fat
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 24) {
                if isCalculating {
                    ProgressView()
                        .scaleEffect(2)
                    Text("Calculating perfect combo...")
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                } else if suggestion.isEmpty {
                    Image(systemName: "face.dashed")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Couldn't find an exact match in your library.")
                        .font(.headline)
                    Text("Try adding more diverse foods (pure protein, pure carbs, pure fats) to your library so the algorithm can combine them!")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 30)
                } else {
                    Text("To hit your remaining macros perfectly, eat this:")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        ForEach(suggestion) { portion in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(portion.food.name).font(.headline)
                                    Text("\(Int(portion.grams))g").font(.subheadline).foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("\(Int(portion.calories)) kcal").font(.headline).foregroundColor(.green)
                                    Text("\(Int(portion.protein))P | \(Int(portion.carbs))C | \(Int(portion.fat))F").font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: logSuggestion) {
                        Text("Log This Combo")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(16)
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    
                    Button(action: calculateSuggestion) {
                        Text("Refresh Suggestion")
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom)
                }
            }
            }
            .navigationTitle("Smart Suggester 🪄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                calculateSuggestion()
            }
        }
    }
    
    private func logSuggestion() {
        for portion in suggestion {
            let meal = ConsumedMeal(
                name: portion.food.name,
                calories: portion.calories,
                protein: portion.protein,
                carbs: portion.carbs,
                fat: portion.fat,
                weightGrams: portion.grams,
                consumedAt: selectedDate,
                mealCategory: autoMealCategory(for: selectedDate),
                fiber: portion.food.fiber.map { $0 * portion.grams / 100.0 },
                sugar: portion.food.sugar.map { $0 * portion.grams / 100.0 },
                saturatedFat: portion.food.saturatedFat.map { $0 * portion.grams / 100.0 },
                sodium: portion.food.sodium.map { $0 * portion.grams / 100.0 }
            )
            context.insert(meal)
            HealthKitManager.shared.saveMeal(
                name: portion.food.name,
                calories: portion.calories,
                protein: portion.protein,
                carbs: portion.carbs,
                fat: portion.fat,
                date: selectedDate
            )
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        HapticManager.shared.notification(.success)
        dismiss()
    }
    
    private func calculateSuggestion() {
        isCalculating = true
        suggestion = []
        
        let foodsToAnalyze = foodLibrary.map { FoodData(from: $0) }
        var freqMap: [String: Int] = [:]
        for m in pastMeals { freqMap[m.name, default: 0] += 1 }
        
        DispatchQueue.global(qos: .userInitiated).async {
            var validFoods = foodsToAnalyze.filter { $0.protein > 0 || $0.carbs > 0 || $0.fat > 0 }
            guard !validFoods.isEmpty else {
                DispatchQueue.main.async { self.isCalculating = false }
                return
            }
            
            validFoods.sort { (freqMap[$0.name] ?? 0) > (freqMap[$1.name] ?? 0) }
            
            var bestComboData: [(id: UUID, grams: Double)] = []
            var bestScore: Double = Double.infinity
            
            // 1. Check single foods
            for food in validFoods.prefix(15) {
                for g in stride(from: 10, through: 500, by: 10) {
                    let grams = Double(g)
                    let p = food.protein * (grams/100.0)
                    let c = food.carbs * (grams/100.0)
                    let f = food.fat * (grams/100.0)
                    
                    let score = abs(self.remProtein - p) + abs(self.remCarbs - c) + abs(self.remFat - f)
                    if score < bestScore {
                        bestScore = score
                        bestComboData = [(food.id, grams)]
                    }
                }
            }
            
            // 2. Check pairs if score isn't perfect yet
            if bestScore > 10 && validFoods.count > 1 {
                let topFoods = Array(validFoods.prefix(10))
                for i in 0..<topFoods.count {
                    for j in (i+1)..<topFoods.count {
                        let f1 = topFoods[i]
                        let f2 = topFoods[j]
                        for g1 in stride(from: 10, through: 300, by: 20) {
                            for g2 in stride(from: 10, through: 300, by: 20) {
                                let grams1 = Double(g1)
                                let grams2 = Double(g2)
                                let p = f1.protein * (grams1/100.0) + f2.protein * (grams2/100.0)
                                let c = f1.carbs * (grams1/100.0) + f2.carbs * (grams2/100.0)
                                let f = f1.fat * (grams1/100.0) + f2.fat * (grams2/100.0)
                                
                                let score = abs(self.remProtein - p) + abs(self.remCarbs - c) + abs(self.remFat - f)
                                if score < bestScore {
                                    bestScore = score
                                    bestComboData = [(f1.id, grams1), (f2.id, grams2)]
                                }
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                if bestScore < 30 {
                    var finalCombo: [FoodPortion] = []
                    for data in bestComboData {
                        if let food = self.foodLibrary.first(where: { $0.id == data.id }) {
                            finalCombo.append(FoodPortion(food: food, grams: data.grams))
                        }
                    }
                    self.suggestion = finalCombo
                }
                self.isCalculating = false
            }
        }
    }
}
