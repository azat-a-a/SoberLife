import SwiftUI

enum CalmTheme {
    static let accent = Color(red: 0.27, green: 0.58, blue: 0.62)
    static let accentSoft = Color(red: 0.70, green: 0.84, blue: 0.86)
    static let surface = Color(red: 0.95, green: 0.98, blue: 0.99)
    static let surfaceStrong = Color.white.opacity(0.9)
    static let sos = Color(red: 0.86, green: 0.55, blue: 0.45)

    static let pageGradient = LinearGradient(
        colors: [
            Color(red: 0.92, green: 0.97, blue: 0.98),
            Color(red: 0.90, green: 0.95, blue: 0.97),
            Color(red: 0.95, green: 0.98, blue: 0.99)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let breatheAnimation: Animation = .easeOut(duration: 0.32)
}

struct CalmCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(CalmTheme.surfaceStrong)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(CalmTheme.accentSoft.opacity(0.45), lineWidth: 1)
                    )
            )
            .shadow(color: CalmTheme.accent.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

struct CalmPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(CalmTheme.accent)
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct CalmSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(CalmTheme.surfaceStrong)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(CalmTheme.accentSoft.opacity(0.6), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

extension View {
    func calmCard() -> some View {
        modifier(CalmCardModifier())
    }

    func calmPageBackground() -> some View {
        background(CalmTheme.pageGradient.ignoresSafeArea())
    }

    func calmSectionTitle() -> some View {
        font(.system(.headline, design: .rounded))
            .foregroundStyle(.secondary.opacity(0.82))
    }

    func calmSecondaryText() -> some View {
        foregroundStyle(.secondary.opacity(0.82))
    }
}
