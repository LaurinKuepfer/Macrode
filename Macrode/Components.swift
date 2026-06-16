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
            // Background Circle
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 20)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    difference < 0 ? 
                        AngularGradient(gradient: Gradient(colors: isSocialDay ? [.orange, .yellow, .orange] : [.red, .pink, .red]), center: .center) : 
                        AngularGradient(gradient: Gradient(colors: [.green, .mint, .green]), center: .center), 
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                .shadow(color: difference < 0 ? (isSocialDay ? Color.orange : Color.red).opacity(0.6) : Color.green.opacity(0.6), radius: 8, x: 0, y: 0)
            
            VStack(spacing: 4) {
                Text("\(abs(difference))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(difference < 0 ? (isSocialDay ? .orange : .red) : .primary)
                    .contentTransition(.numericText())
                
                Text(difference < 0 ? (isSocialDay ? "Social Day" : "Over") : "Left")
                    .font(.headline)
                    .foregroundColor(difference < 0 ? (isSocialDay ? .orange : .red) : .secondary)
            }
        }
        .frame(width: 220, height: 220)
    }
}

struct MacroBar: View {
    let title: String
    let consumed: Double
    let target: Double
    let baseColor: Color
    
    // NEW: If they hit the goal, turn it Gold!
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
                    .foregroundColor(consumed >= target ? .yellow : .secondary)
                    .fontWeight(consumed >= target ? .bold : .regular)
                    .contentTransition(.numericText())
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            consumed >= target ? 
                                LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .leading, endPoint: .trailing) : 
                                LinearGradient(gradient: Gradient(colors: [baseColor, baseColor.opacity(0.6)]), startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: min(geometry.size.width * CGFloat(consumed / target), geometry.size.width), height: 12)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: consumed)
                }
            }
            .frame(height: 12)
        }
    }
}

struct MealRow: View {
    let meal: ConsumedMeal
    
    var body: some View {
        HStack {
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
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
