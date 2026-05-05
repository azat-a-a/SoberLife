import SwiftUI

public struct AppShellView: View {
    @ObservedObject private var sessionState: SessionState

    public init(sessionState: SessionState) {
        self.sessionState = sessionState
    }

    public var body: some View {
        Group {
            switch sessionState.authState {
            case .signedOut:
                SignedOutPlaceholderView(
                    errorMessage: sessionState.authErrorMessage,
                    onSignInTap: {
                        Task {
                            await sessionState.signInWithApple()
                        }
                    }
                )
            case .signedIn:
                MainTabView(
                    onSignOutTap: {
                        Task {
                            await sessionState.signOut()
                        }
                    }
                )
            }
        }
        .task {
            await sessionState.restoreSession()
        }
    }
}

private struct MainTabView: View {
    let onSignOutTap: () -> Void

    var body: some View {
        TabView {
            HomePlaceholderView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            AIChatPlaceholderView()
                .tabItem {
                    Label("AI Chat", systemImage: "message")
                }

            StatsPlaceholderView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }

            ProfilePlaceholderView(onSignOutTap: onSignOutTap)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

private struct SignedOutPlaceholderView: View {
    let errorMessage: String?
    let onSignInTap: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("SoberLife")
                    .font(.largeTitle)
                    .bold()

                Text("Apple Sign-In flow is scaffolded. Real token exchange is wired through AuthService.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                Button("Sign In Placeholder", action: onSignInTap)
                    .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .navigationTitle("Welcome")
        }
    }
}

private struct HomePlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Home")
                    .font(.title2)
                    .bold()
                Text("Sobriety counter and milestones will be implemented in Sprint 02.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            .navigationTitle("Home")
        }
    }
}

private struct AIChatPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Chat")
                    .font(.title2)
                    .bold()
                Text("DeepSeek chat and SOS flow will be connected in Sprint 03.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            .navigationTitle("AI Chat")
        }
    }
}

private struct StatsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Stats")
                    .font(.title2)
                    .bold()
                Text("Saved money, streak trends, and achievements are planned for Sprint 02.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            .navigationTitle("Stats")
        }
    }
}

private struct ProfilePlaceholderView: View {
    let onSignOutTap: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Profile")
                    .font(.title2)
                    .bold()
                Text("Settings, privacy, and legal screens are wired in later milestones.")
                    .foregroundStyle(.secondary)

                Button("Sign Out Placeholder", action: onSignOutTap)
                    .buttonStyle(.bordered)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            .navigationTitle("Profile")
        }
    }
}
