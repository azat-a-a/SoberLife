import SwiftUI
import SoberLifeCore

struct AIChatTabView: View {
    @ObservedObject private var sessionState: SessionState
    @StateObject private var state: AIChatState

    init(
        sessionState: SessionState,
        userID: UUID,
        onboardingStore: OnboardingStore,
        aiService: (any AIService)?,
        authWiring: AuthWiring?
    ) {
        self.sessionState = sessionState
        let http = authWiring.map {
            HTTPSupabaseService(baseURL: $0.supabaseURL, anonKey: $0.supabaseAnonKey)
        }
        _state = StateObject(
            wrappedValue: AIChatState(
                userID: userID,
                onboardingStore: onboardingStore,
                aiService: aiService,
                supabaseHTTP: http,
                tokenProvider: { await sessionState.accessTokenIfAvailable() }
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let err = state.errorMessage {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if state.messages.isEmpty && !state.isLoading {
                                Text(EmpathyCopy.chatEmptyHint)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            }

                            ForEach(state.messages.indices, id: \.self) { index in
                                chatBubble(state.messages[index])
                            }

                            Color.clear.frame(height: 1).id("chatBottom")
                        }
                        .padding()
                    }
                    .onChange(of: state.messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo("chatBottom", anchor: .bottom)
                        }
                    }
                }

                HStack(alignment: .bottom, spacing: 10) {
                    TextField("Message", text: $state.draft, axis: .vertical)
                        .lineLimit(1...6)
                        .padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))

                    Button {
                        Task { await state.sendDraft() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .disabled(
                        state.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || state.isSending
                    )
                    .accessibilityLabel("Send")
                }
                .padding()
                .background(.background)
            }
            .navigationTitle("AI Chat")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New chat") {
                        state.startNewConversation()
                    }
                }
            }
            .overlay {
                if state.isLoading && state.messages.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.thinMaterial.opacity(0.5))
                }
            }
            .task {
                await state.load()
            }
        }
    }

    @ViewBuilder
    private func chatBubble(_ message: ChatMessage) -> some View {
        let isUser = message.role == "user"
        HStack(alignment: .top) {
            if isUser { Spacer(minLength: 48) }
            Text(message.content)
                .font(.body)
                .padding(12)
                .background(
                    isUser ? Color.blue.opacity(0.18) : Color.secondary.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            if !isUser { Spacer(minLength: 48) }
        }
    }
}
