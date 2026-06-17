import SwiftUI

struct WidgetPromoBanner: View {
    @AppStorage("hasDismissedWidgetPromo") private var hasDismissedWidgetPromo = false
    
    var body: some View {
        if !hasDismissedWidgetPromo {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New: Lock Screen Widgets! 📱")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Track your calories and macros without opening the app. Long-press your home screen or lock screen to add the Macrode widget.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Button(action: {
                        withAnimation {
                            hasDismissedWidgetPromo = true
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
                
                HStack(spacing: 16) {
                    Circle()
                        .stroke(Color.green, lineWidth: 6)
                        .frame(width: 40, height: 40)
                        .overlay(Text("1200").font(.system(size: 10, weight: .bold)))
                    VStack(alignment: .leading) {
                        Text("Macrode").font(.caption).fontWeight(.bold)
                        Text("1200 kcal left").font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.2), Color.blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 24)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
