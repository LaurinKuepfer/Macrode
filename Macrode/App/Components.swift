import SwiftUI

struct CalorieHUD: View {
    var consumed: Double
    var target: Double
    var isSocialDay: Bool = false
    
    private var progress: Double {
        min(consumed / target, 1.0)
    }
    
    private var difference: Int {
        Int(target - consumed)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 16)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    difference < 0 ? 
                        AngularGradient(gradient: Gradient(colors: isSocialDay ? [.orange, .yellow, .orange] : [.red, .pink, .red]), center: .center) : 
                        AngularGradient(gradient: Gradient(colors: [.green, .mint, .green]), center: .center), 
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                .shadow(color: difference < 0 ? (isSocialDay ? Color.orange : Color.red).opacity(0.4) : Color.green.opacity(0.4), radius: 6, x: 0, y: 2)
            
            VStack(spacing: 4) {
                Text("\(abs(difference))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(difference < 0 ? (isSocialDay ? .orange : .red) : .primary)
                    .contentTransition(.numericText())
                
                Text(difference < 0 ? (isSocialDay ? "Social Day" : "Over") : "Left")
                    .font(.system(.headline, design: .rounded, weight: .medium))
                    .foregroundColor(difference < 0 ? (isSocialDay ? .orange : .red) : .secondary)
            }
        }
        .frame(minWidth: 200, minHeight: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Calories")
        .accessibilityValue(difference < 0 ? "\(abs(difference)) calories over target" : "\(abs(difference)) calories left")
    }
}

struct MacroBar: View {
    let title: String
    let consumed: Double
    let target: Double
    let baseColor: Color
    
    private var displayColor: Color {
        consumed >= target ? Color.yellow : baseColor
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(consumed)) / \(Int(target))g")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(consumed >= target ? .orange : .secondary)
                    .fontWeight(consumed >= target ? .bold : .regular)
                    .contentTransition(.numericText())
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(minHeight: 10)
                    
                    Capsule()
                        .fill(
                            consumed >= target ? 
                                LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .leading, endPoint: .trailing) : 
                                LinearGradient(gradient: Gradient(colors: [baseColor, baseColor.opacity(0.7)]), startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: min(geometry.size.width * CGFloat(consumed / target), geometry.size.width))
                        .frame(minHeight: 10)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: consumed)
                }
            }
            .frame(minHeight: 10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) Macros")
        .accessibilityValue("\(Int(consumed)) grams consumed out of \(Int(target)) grams")
    }
}

struct MealRow: View {
    let meal: ConsumedMeal
    var isNested: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(colorForCategory(meal.mealCategory).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: iconForCategory(meal.mealCategory))
                    .font(.title3)
                    .foregroundColor(colorForCategory(meal.mealCategory))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text("\(Int(meal.protein))g P")
                        .foregroundColor(.red)
                    Text("\(Int(meal.carbs))g C")
                        .foregroundColor(.blue)
                    Text("\(Int(meal.fat))g F")
                        .foregroundColor(.orange)
                }
                .font(.caption2)
                .fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(meal.calories)) kcal")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.green)
                Text(meal.consumedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(isNested ? 8 : 16)
        .background(
            Group {
                if !isNested {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                }
            }
        )
        .accessibilityElement(children: .combine)
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Breakfast": return "sunrise.fill"
        case "Lunch": return "sun.max.fill"
        case "Dinner": return "moon.stars.fill"
        default: return "leaf.fill"
        }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Breakfast": return .orange
        case "Lunch": return .yellow
        case "Dinner": return .indigo
        default: return .green
        }
    }
}


struct StatBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.weight(.bold))
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

