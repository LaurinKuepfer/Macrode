import SwiftUI
import SwiftData
import WidgetKit

enum GoalType: String, CaseIterable {
    case lose = "Lose Weight"
    case maintain = "Maintain"
    case gain = "Build Muscle"
}

struct CalculatorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    
    var dailyLog: DailyLog
    
    @State private var isMale: Bool = true
    @State private var age: String = ""
    @State private var heightCM: String = ""
    @State private var weightKG: String = ""
    
    @AppStorage("userGoal") private var goal: GoalType = .maintain
    @State private var activityLevel: ActivityLevel = .sedentary
    
    @FocusState private var isInputActive: Bool
    
    enum ActivityLevel: String, CaseIterable {
        case sedentary = "Office Job"
        case light = "Light (1-2x/Wk)"
        case active = "Active (3-5x/Wk)"
        case athlete = "Athlete (Daily)"
        
        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .light: return 1.375
            case .active: return 1.55
            case .athlete: return 1.725
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Body Stats")) {
                    Picker("Gender", selection: $isMale) {
                        Text("Male").tag(true)
                        Text("Female").tag(false)
                    }.pickerStyle(.segmented)
                    
                    HStack { Text("Age"); Spacer(); TextField("Years", text: $age).keyboardType(.numberPad).focused($isInputActive).multilineTextAlignment(.trailing) }
                    HStack { Text("Height"); Spacer(); TextField("cm", text: $heightCM).keyboardType(.numberPad).focused($isInputActive).multilineTextAlignment(.trailing) }
                    HStack { Text("Weight"); Spacer(); TextField("kg", text: $weightKG).keyboardType(.decimalPad).focused($isInputActive).multilineTextAlignment(.trailing) }
                }
                
                Section(header: Text("Goals & Activity")) {
                    Picker("Goal", selection: $goal) {
                        ForEach(GoalType.allCases, id: \.self) { type in Text(type.rawValue).tag(type) }
                    }.pickerStyle(.menu)
                    
                    Picker("Activity", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { type in Text(type.rawValue).tag(type) }
                    }.pickerStyle(.menu)
                }
                
                Section(footer: Text("This will recalculate and overwrite your macro targets for today.")) {
                    Button(action: calculateAndSave) {
                        Text("Recalculate Macros")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .listRowBackground(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .disabled(age.isEmpty || heightCM.isEmpty || weightKG.isEmpty)
                }
            }
            .navigationTitle("Macro Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .keyboard) { Button("Done") { isInputActive = false }.frame(maxWidth: .infinity, alignment: .trailing) }
            }
            .onAppear {
                if let w = dailyLog.bodyWeight {
                    weightKG = String(w)
                }
            }
        }
    }
    
    private func calculateAndSave() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let w = Double(weightKG.replacingOccurrences(of: ",", with: ".")) ?? 70.0
        let h = Double(heightCM) ?? 170.0
        let a = Double(age) ?? 30.0
        
        var bmr = (10.0 * w) + (6.25 * h) - (5.0 * a)
        bmr += isMale ? 5.0 : -161.0
        
        var tdee = bmr * activityLevel.multiplier
        
        if goal == .lose { tdee -= 500 }
        if goal == .gain { tdee += 300 }
        
        let roundedTdee = round(tdee)
        let proteinPerKg = (activityLevel == .active || activityLevel == .athlete || goal == .gain) ? 2.0 : 1.6
        let proteinTarget = round(w * proteinPerKg)
        let fatTarget = round((tdee * 0.25) / 9.0)
        let remainingCals = tdee - (proteinTarget * 4.0) - (fatTarget * 9.0)
        let carbsTarget = round(max(0, remainingCals / 4.0))
        
        dailyLog.calorieTarget = roundedTdee
        dailyLog.proteinTarget = proteinTarget
        dailyLog.carbsTarget = carbsTarget
        dailyLog.fatTarget = fatTarget
        dailyLog.bodyWeight = w
        dailyLog.waterTargetML = Int((w / 20.0) * 1000)
        
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        
        dismiss()
    }
}
