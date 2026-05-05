import Foundation
import Combine
import SoberLifeCore

@MainActor
public final class AIChatState: ObservableObject {
    @Published public private(set) var messages: [ChatMessage] = []
    @Published public private(set) var remoteConversationId: UUID?
    @Published public private(set) var isLoading = false
    @Published public private(set) var isSending = false
    @Published public var errorMessage: String?
    @Published public var draft: String = ""

    private let userID: UUID
    private let onboardingStore: OnboardingStore
    private let aiService: (any AIService)?
    private let supabaseHTTP: HTTPSupabaseService?
    private let tokenProvider: @Sendable () async -> String?
    private let localStore: UserDefaultsAIChatTranscriptStore

    public init(
        userID: UUID,
        onboardingStore: OnboardingStore,
        aiService: (any AIService)?,
        supabaseHTTP: HTTPSupabaseService?,
        tokenProvider: @escaping @Sendable () async -> String?,
        localStore: UserDefaultsAIChatTranscriptStore = UserDefaultsAIChatTranscriptStore()
    ) {
        self.userID = userID
        self.onboardingStore = onboardingStore
        self.aiService = aiService
        self.supabaseHTTP = supabaseHTTP
        self.tokenProvider = tokenProvider
        self.localStore = localStore
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if let token = await tokenProvider(),
           SupabaseJWT.isLikelyUserAccessToken(token),
           let http = supabaseHTTP
        {
            let store = SupabaseAIChatHistoryStore(http: http)
            do {
                if let pair = try await store.fetchLatestChat(userID: userID, bearerToken: token) {
                    remoteConversationId = pair.id
                    messages = pair.messages
                    localStore.save(userID: userID, remoteId: pair.id, messages: pair.messages)
                    return
                }
            } catch {
                errorMessage = EmpathyCopy.chatCloudLoadFailed
            }
        }

        let local = localStore.load(userID: userID)
        remoteConversationId = local.remoteId
        messages = local.messages
    }

    public func sendDraft() async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let aiService else {
            errorMessage = EmpathyCopy.chatNeedsBackend
            return
        }

        draft = ""
        isSending = true
        defer { isSending = false }

        let userMsg = ChatMessage(role: "user", content: trimmed, timestamp: Date())
        messages.append(userMsg)
        await persist()

        let context = AIContext(
            soberDays: currentSoberDays(),
            recentTriggers: [],
            recentJournalNotes: []
        )

        do {
            let reply = try await aiService.send(
                userID: userID,
                conversationType: .chat,
                messages: messages,
                context: context
            )
            let assistant = ChatMessage(role: "assistant", content: reply.reply, timestamp: Date())
            messages.append(assistant)
            await persist()
            errorMessage = nil
        } catch {
            errorMessage = EmpathyCopy.chatSendFailed
        }
    }

    public func startNewConversation() {
        messages = []
        remoteConversationId = nil
        localStore.save(userID: userID, remoteId: nil, messages: [])
        errorMessage = nil
    }

    private func currentSoberDays() -> Int? {
        guard let profile = onboardingStore.loadProfile(userID: userID) else { return nil }
        return SobrietyCounter.soberDays(since: profile.sobrietyStartDate, now: Date(), calendar: .current)
    }

    private func persist() async {
        localStore.save(userID: userID, remoteId: remoteConversationId, messages: messages)

        guard let token = await tokenProvider(),
              SupabaseJWT.isLikelyUserAccessToken(token),
              let http = supabaseHTTP
        else { return }

        let store = SupabaseAIChatHistoryStore(http: http)
        do {
            if let id = remoteConversationId {
                try await store.updateMessages(conversationId: id, messages: messages, bearerToken: token)
            } else if !messages.isEmpty {
                let id = try await store.insertChat(userID: userID, messages: messages, bearerToken: token)
                remoteConversationId = id
                localStore.save(userID: userID, remoteId: id, messages: messages)
            }
        } catch {
            errorMessage = EmpathyCopy.chatCloudSyncFailed
        }
    }
}
