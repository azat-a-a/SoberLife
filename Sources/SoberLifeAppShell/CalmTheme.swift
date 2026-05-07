import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum CalmTheme {
    #if canImport(UIKit)
    private static func dynamic(_ light: UIColor, _ dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
    #else
    private static func dynamic(_ light: Color, _ dark: Color) -> Color { light }
    #endif

    static let accent: Color = {
        #if canImport(UIKit)
        dynamic(
            UIColor(red: 0.27, green: 0.58, blue: 0.62, alpha: 1),
            UIColor(red: 0.38, green: 0.70, blue: 0.74, alpha: 1)
        )
        #else
        Color(red: 0.27, green: 0.58, blue: 0.62)
        #endif
    }()

    static let accentSoft: Color = {
        #if canImport(UIKit)
        dynamic(
            UIColor(red: 0.70, green: 0.84, blue: 0.86, alpha: 1),
            UIColor(red: 0.23, green: 0.35, blue: 0.38, alpha: 1)
        )
        #else
        Color(red: 0.70, green: 0.84, blue: 0.86)
        #endif
    }()

    static let surface: Color = {
        #if canImport(UIKit)
        dynamic(
            UIColor(red: 0.95, green: 0.98, blue: 0.99, alpha: 1),
            UIColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1)
        )
        #else
        Color(red: 0.95, green: 0.98, blue: 0.99)
        #endif
    }()

    static let surfaceStrong: Color = {
        #if canImport(UIKit)
        dynamic(
            UIColor.white.withAlphaComponent(0.9),
            UIColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 0.92)
        )
        #else
        Color.white.opacity(0.9)
        #endif
    }()

    static let sos: Color = {
        #if canImport(UIKit)
        dynamic(
            UIColor(red: 0.86, green: 0.55, blue: 0.45, alpha: 1),
            UIColor(red: 0.90, green: 0.62, blue: 0.52, alpha: 1)
        )
        #else
        Color(red: 0.86, green: 0.55, blue: 0.45)
        #endif
    }()

    static let backdropVeil: Color = {
        #if canImport(UIKit)
        dynamic(
            UIColor.white.withAlphaComponent(0.14),
            UIColor.black.withAlphaComponent(0.34)
        )
        #else
        Color.black.opacity(0.2)
        #endif
    }()

    static let pageGradient: LinearGradient = {
        #if canImport(UIKit)
        LinearGradient(
            colors: [
                dynamic(
                    UIColor(red: 0.92, green: 0.97, blue: 0.98, alpha: 1),
                    UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1)
                ),
                dynamic(
                    UIColor(red: 0.90, green: 0.95, blue: 0.97, alpha: 1),
                    UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1)
                ),
                dynamic(
                    UIColor(red: 0.95, green: 0.98, blue: 0.99, alpha: 1),
                    UIColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1)
                )
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        #else
        LinearGradient(
            colors: [
                Color(red: 0.92, green: 0.97, blue: 0.98),
                Color(red: 0.90, green: 0.95, blue: 0.97),
                Color(red: 0.95, green: 0.98, blue: 0.99)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        #endif
    }()

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
            .shadow(color: CalmTheme.accent.opacity(0.07), radius: 10, x: 0, y: 4)
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
        background(
            ZStack {
                Image("meditative-background", bundle: .module)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                CalmTheme.pageGradient.opacity(0.42)
                    .ignoresSafeArea()
                CalmTheme.backdropVeil
                    .ignoresSafeArea()
            }
        )
    }

    func calmSectionTitle() -> some View {
        font(.system(.headline, design: .rounded))
            .foregroundStyle(.secondary.opacity(0.82))
    }

    func calmSecondaryText() -> some View {
        foregroundStyle(.secondary.opacity(0.82))
    }
}
