
import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var text: String?

    func body(content: Content) -> some View {
        ZStack {
            content
            if let text {
                Text(text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.accent, lineWidth: 1))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { self.text = nil }
                        }
                    }
                    .padding(.top, 50)
            }
        }
        .animation(.easeInOut, value: text)
    }
}

extension View {
    func toast(_ text: Binding<String?>) -> some View {
        self.modifier(ToastModifier(text: text))
    }
}
