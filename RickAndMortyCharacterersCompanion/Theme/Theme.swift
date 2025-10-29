
import SwiftUI

enum Theme {
    // Calm and readable palette
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let accent = Color("Accent")
    static let accentAlt = Color("AccentAlt")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
}

// Fallbacks if you do not add asset colors
extension Color {
    init(_ light: Double, _ alpha: Double = 1.0) {
        self = Color(white: light, opacity: alpha)
    }
}

struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding()
            .background(Theme.surface.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(radius: 4)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
