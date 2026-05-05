import Foundation
import Combine
import SoberLifeCore

@MainActor
public final class AIChatState: ObservableObject {
    @Published public private(set) var threads: [AIChatThread] = []
    @Published public private(set) var selectedConversationId: UUID?
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
    private let onUnauthorized: @MainActor @Sendable () async -> Void
    private let localStore: UserDefaultsAIChatTranscriptStore

    public init(
        userID: UUID,
        onboardingStore: OnboardingStore,
        aiService: (any AIService)?,
        supabaseHTTP: HTTPSupabaseService?,
        tokenProvider: @escaping @Sendable () async -> String?,
        onUnauthorized: @escaping @MainActor @Sendable () async -> Void = {},
        localStore: UserDefaultsAIChatTranscriptStore = UserDefaultsAIChatTranscriptStore()
    ) {
        self.userID = userID
        self.onboardingStore = onboardingStore
        self.aiService = aiService
        self.supabaseHTTP = supabaseHTTP
        self.tokenProvider = tokenProvider
        self.onUnauthorized = onUnauthorized
        self.localStore = localStore
    }

    public var canRetryAssistant: Bool {
        errorMessage != nil
            && !messages.isEmpty
            && messages.last?.role == "user"
            && aiService != nil
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let local = localStore.load(userID: userID)

        if let token = await tokenProvider(),
           SupabaseJWT.isLikelyUserAccessToken(token),
           let http = supabaseHTTP
        {
            let store = SupabaseAIChatHistoryStore(http: http)
            do {
                let list = try await store.fetchChatThreads(userID: userID, bearerToken: token)
                threads = list

                let preferredId = local.selectedConversationId
                let chosen: AIChatThread? = {
                    if let preferredId, let thread = list.first(where: { $0.id == preferredId }) {
                        return thread
                    }
                    return list.first
                }()

                if let thread = chosen {
                    applyThread(thread)
                } else {
                    selectedConversationId = nil
                    remoteConversationId = nil
                    messages = []
                }
                persistLocalSnapshot()
                return
            } catch {
                if await handleSupabaseError(error, fallbackMessage: EmpathyCopy.chatCloudLoadFailed) {
                    return
                }
            }
        }

        threads = []
        selectedConversationId = local.selectedConversationId
        remoteConversationId = local.remoteId
        messages = local.messages
    }

    public func selectThread(_ id: UUID?) async {
        errorMessage = nil
        guard let id else {
            selectedConversationId = nil
            remoteConversationId = nil
            messages = []
            persistLocalSnapshot()
            return
        }

        if let existing = threads.first(where: { $0.id == id }) {
            applyThread(existing)
            persistLocalSnapshot()
            return
        }

        guard let token = await tokenProvider(),
              SupabaseJWT.isLikelyUserAccessToken(token),
              let http = supabaseHTTP
        else { return }

        let store = SupabaseAIChatHistoryStore(http: http)
        let thread: AIChatThread
        do {
            guard let fetched = try await store.fetchConversation(id: id, bearerToken: token) else { return }
            thread = fetched
        } catch {
            _ = await handleSupabaseError(error, fallbackMessage: EmpathyCopy.chatCloudLoadFailed)
            return
        }

        if let idx = threads.firstIndex(where: { $0.id == id }) {
            threads[idx] = thread
        } else {
            threads.insert(thread, at: 0)
            threads.sort { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        }
        applyThread(thread)
        persistLocalSnapshot()
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

        await requestAssistantReply(using: aiService)
    }

    public func retryAssistantReply() async {
        guard let aiService, canRetryAssistant else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        await requestAssistantReply(using: aiService)
    }

    public func startNewConversation() {
        selectedConversationId = nil
        remoteConversationId = nil
        messages = []
        errorMessage = nil
        persistLocalSnapshot()
    }

    private func requestAssistantReply(using aiService: any AIService) async {
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
            refreshThreadInList()
            errorMessage = nil
        } catch {
            errorMessage = EmpathyCopy.chatSendFailed
        }
    }

    private func currentSoberDays() -> Int? {
        guard let profile = onboardingStore.loadProfile(userID: userID) else { return nil }
        return SobrietyCounter.soberDays(since: profile.sobrietyStartDate, now: Date(), calendar: .current)
    }

    private func applyThread(_ thread: AIChatThread) {
        selectedConversationId = thread.id
        remoteConversationId = thread.id
        messages = thread.messages
    }

    private func refreshThreadInList() {
        guard let id = remoteConversationId else { return }
        let created = threads.first(where: { $0.id == id })?.createdAt
        let updated = AIChatThread(id: id, createdAt: created ?? Date(), messages: messages)
        if let idx = threads.firstIndex(where: { $0.id == id }) {
            threads[idx] = updated
        } else {
            threads.insert(updated, at: 0)
        }
        threads.sort { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    private func persistLocalSnapshot() {
        let snapshot = ChatLocalSnapshot(
            remoteId: remoteConversationId,
            selectedConversationId: selectedConversationId,
            messages: messages
        )
        localStore.save(snapshot, userID: userID)
    }

    private func persist() async {
        persistLocalSnapshot()

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
                selectedConversationId = id
                let priorCreated = threads.first(where: { $0.id == id })?.createdAt
                let thread = AIChatThread(id: id, createdAt: priorCreated ?? Date(), messages: messages)
                if let idx = threads.firstIndex(where: { $0.id == id }) {
                    threads[idx] = thread
                } else {
                    threads.insert(thread, at: 0)
                }
                threads.sort { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
                persistLocalSnapshot()
            }
        } catch {
            _ = await handleSupabaseError(error, fallbackMessage: EmpathyCopy.chatCloudSyncFailed)
        }
    }

    @discardableResult
    private func handleSupabaseError(_ error: Error, fallbackMessage: String) async -> Bool {
        if case SupabaseHTTPServiceError.httpStatus(401) = error {
            errorMessage = EmpathyCopy.sessionExpiredNeedsSignIn
            await onUnauthorized()
            return true
        }
        if let urlError = error as? URLError, Self.isOfflineError(urlError) {
            errorMessage = EmpathyCopy.networkOfflineShort
            return true
        }
        errorMessage = fallbackMessage
        return false
    }

    private static func isOfflineError(_ error: URLError) -> Bool {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }
}
