import SwiftUI

struct PremiumBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if colorScheme == .dark {
            // Inspired by sleek fitness apps, but uniquely Macrode
            // A deep slate/charcoal with a subtle top glow
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.16, green: 0.18, blue: 0.22), // Subtle slate glow at the top
                    Color(red: 0.05, green: 0.06, blue: 0.08)  // Deep charcoal/black edges
                ]),
                center: .top,
                startRadius: 20,
                endRadius: 800
            )
            .ignoresSafeArea()
        } else {
            // Bringing the exact same premium radial glow style to Light Mode
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.99, green: 0.99, blue: 1.0), // Bright clean center
                    Color(red: 0.88, green: 0.89, blue: 0.92)  // Sleek silver/gray edges
                ]),
                center: .top,
                startRadius: 20,
                endRadius: 800
            )
            .ignoresSafeArea()
        }
    }
}

struct BackgroundTextureModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        ZStack {
            PremiumBackground()
            
            GeometryReader { proxy in
                Image("NoiseTexture")
                    .resizable(resizingMode: .tile)
                    .opacity(colorScheme == .dark ? 0.03 : 0.05) // Subtle texture for depth
                    .blendMode(colorScheme == .dark ? .screen : .multiply)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            content
        }
    }
}

extension View {
    func adaptiveBackgroundTexture() -> some View {
        self.modifier(BackgroundTextureModifier())
    }
}
