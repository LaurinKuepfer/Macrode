import SwiftUI

struct TourStep {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

let macrodeTourSteps: [TourStep] = [
    TourStep(icon: "target", title: "Adjust Your Goals", description: "Tap the target icon on the dashboard to change your calories, protein, or weight goals."),
    TourStep(icon: "arrow.up.arrow.down", title: "Customize Dashboard", description: "Scroll down and tap 'Edit Layout' to hide or reorder your dashboard blocks."),
    TourStep(icon: "barcode.viewfinder", title: "Barcode Scanner", description: "In the Library tab, tap the scanner icon in the top right to instantly log packaged foods."),
    TourStep(icon: "calendar.badge.clock", title: "Weekly & Monthly Reviews", description: "Check your Insights tab for detailed reports and consistency scores.")
]

struct FeatureTourBanner: View {
    @AppStorage("hasCompletedFeatureTour") private var hasCompletedFeatureTour: Bool = false
    @State private var currentStepIndex: Int = 0
    @State private var isVisible: Bool = false
    
    var body: some View {
        if !hasCompletedFeatureTour && isVisible {
            let step = macrodeTourSteps[currentStepIndex]
            
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: step.icon)
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(step.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            hasCompletedFeatureTour = true
                            isVisible = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                HStack {
                    Text("\(currentStepIndex + 1) of \(macrodeTourSteps.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            if currentStepIndex < macrodeTourSteps.count - 1 {
                                currentStepIndex += 1
                            } else {
                                hasCompletedFeatureTour = true
                                isVisible = false
                            }
                        }
                    }) {
                        Text(currentStepIndex < macrodeTourSteps.count - 1 ? "Next Tip" : "Done")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
            .padding(.horizontal)
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            Color.clear.frame(height: 0).onAppear {
                if !hasCompletedFeatureTour {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.spring()) {
                            isVisible = true
                        }
                    }
                }
            }
        }
    }
}
