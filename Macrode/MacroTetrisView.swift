import SwiftUI
import SwiftData
import WidgetKit

struct MacroTetrisView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Query private var foodLibrary: [FoodItem]
    
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
            .navigationTitle("Macro Tetris 🧩")
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
    
    // Core Algorithm
    private func calculateSuggestion() {
        isCalculating = true
        suggestion = []
        
        // Run in background to avoid freezing the UI
        DispatchQueue.global(qos: .userInitiated).async {
            // Filter foods that have some macros
            let validFoods = self.foodLibrary.filter { $0.protein > 0 || $0.carbs > 0 || $0.fat > 0 }
            guard !validFoods.isEmpty else {
                DispatchQueue.main.async { self.isCalculating = false }
                return
            }
            
            var bestCombo: [FoodPortion] = []
            var bestScore: Double = Double.infinity
            
            // Try random combinations to find a good fit quickly
            // This is a naive random search, but fast and fun
            for _ in 0..<2000 {
                let numItems = Int.random(in: 1...3)
                var currentCombo: [FoodPortion] = []
                var p: Double = 0
                var c: Double = 0
                var f: Double = 0
                
                for _ in 0..<numItems {
                    guard let randomFood = validFoods.randomElement() else { continue }
                    // Random portion between 10g and 300g
                    let randomGrams = Double(Int.random(in: 1...30) * 10)
                    let portion = FoodPortion(food: randomFood, grams: randomGrams)
                    currentCombo.append(portion)
                    
                    p += portion.protein
                    c += portion.carbs
                    f += portion.fat
                }
                
                // Calculate distance to target (score, lower is better)
                let pDiff = abs(self.remProtein - p)
                let cDiff = abs(self.remCarbs - c)
                let fDiff = abs(self.remFat - f)
                let score = pDiff + cDiff + fDiff
                
                if score < bestScore {
                    bestScore = score
                    bestCombo = currentCombo
                }
            }
            
            DispatchQueue.main.async {
                // If the best score is acceptable (within ~20g total off)
                if bestScore < 30 {
                    self.suggestion = bestCombo
                }
                self.isCalculating = false
            }
        }
    }
}
