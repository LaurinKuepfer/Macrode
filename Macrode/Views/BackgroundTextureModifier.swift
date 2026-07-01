import SwiftUI

struct BackgroundTextureModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            GeometryReader { proxy in
                Image("NoiseTexture")
                    .resizable(resizingMode: .tile)
                    .opacity(colorScheme == .dark ? 0.04 : 0.06)
                    .blendMode(colorScheme == .dark ? .screen : .multiply)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}

extension View {
    func adaptiveBackgroundTexture() -> some View {
        self.modifier(BackgroundTextureModifier())
    }
}
