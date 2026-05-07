import SwiftUI
import SoberLifeCore

@MainActor
struct SOSFlowView: View {
    let userID: UUID
    let contact: SupportContact
    let soberDays: Int
    let aiService: (any AIService)?

    @Environment(\.openURL) private var openURL
    @State private var aiReply: String?
    @State private var aiErrorMessage: String?
    @State private var isLoadingAI = false
    @State private var aiFeedbackTick = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(EmpathyCopy.sosTitle)
                    .font(.title2)
                    .bold()
                    .fontDesign(.rounded)
                Text(EmpathyCopy.sosSubtitle)
                    .calmSecondaryText()

                quickAction(
                    title: EmpathyCopy.sosBreathingTitle,
                    detail: EmpathyCopy.sosBreathingDetail,
                    systemImage: "wind"
                )
                quickAction(
                    title: EmpathyCopy.sosWaterTitle,
                    detail: EmpathyCopy.sosWaterDetail,
                    systemImage: "drop.fill"
                )
                quickAction(
                    title: EmpathyCopy.sosGroundingTitle,
                    detail: EmpathyCopy.sosGroundingDetail,
                    systemImage: "leaf.fill"
                )

                if contact.hasCallableNumber {
                    VStack(alignment: .leading, spacing: 8) {
                        L10n.text("sos.contact.title")
                            .font(.headline)
                        Text(contact.trustedName.isEmpty ? L10n.string("sos.contact.placeholder") : contact.trustedName)
                            .calmSecondaryText()
                        HStack {
                            if let url = Self.callURL(phone: contact.trustedPhone) {
                                Button {
                                    openURL(url)
                                } label: {
                                    Label {
                                        L10n.text("sos.call")
                                    } icon: {
                                        Image(systemName: "phone.fill")
                                    }
                                }
                                .buttonStyle(CalmPrimaryButtonStyle())
                                .tint(CalmTheme.sos)
                            }
                            if let url = Self.smsURL(phone: contact.trustedPhone) {
                                Button {
                                    openURL(url)
                                } label: {
                                    Label {
                                        L10n.text("sos.message")
                                    } icon: {
                                        Image(systemName: "message.fill")
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(CalmTheme.accent)
                            }
                        }
                    }
                    .calmCard()
                }

                if aiService != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        if let aiErrorMessage {
                            Text(aiErrorMessage)
                                .font(.footnote)
                                .foregroundStyle(CalmTheme.sos)
                        }
                        if let aiReply {
                            Text(aiReply)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        Button {
                            Task { await loadAI() }
                        } label: {
                            if isLoadingAI {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text(EmpathyCopy.sosAiButton)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(CalmPrimaryButtonStyle())
                        .disabled(isLoadingAI)
                    }
                } else {
                    Text(EmpathyCopy.sosAiFallback)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .calmCard()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(EmpathyCopy.sosCrisisSection)
                        .calmSectionTitle()
                    Text(EmpathyCopy.sosCrisisBody)
                        .calmSecondaryText()
                    if let url = URL(string: "https://findahelpline.com") {
                        Link(L10n.string("sos.helpline"), destination: url)
                    }
                }
                .padding()
                .background(CalmTheme.sos.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .calmPageBackground()
        .tint(CalmTheme.accent)
        .animation(CalmTheme.breatheAnimation, value: isLoadingAI)
        .sensoryFeedback(.selection, trigger: isLoadingAI)
        .sensoryFeedback(.success, trigger: aiFeedbackTick)
    }

    private func quickAction(title: String, detail: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .calmCard()
    }

    private func loadAI() async {
        guard let aiService else { return }
        isLoadingAI = true
        aiErrorMessage = nil
        defer { isLoadingAI = false }
        let message = ChatMessage(
            role: "user",
            content: L10n.string("sos.ai.prompt"),
            timestamp: Date()
        )
        let context = AIContext(soberDays: soberDays, recentTriggers: [], recentJournalNotes: [])
        do {
            let reply = try await aiService.send(
                userID: userID,
                conversationType: .sos,
                messages: [message],
                context: context
            )
            aiReply = reply.reply
            aiFeedbackTick += 1
        } catch {
            if let urlError = error as? URLError,
               Self.isOfflineError(urlError)
            {
                aiErrorMessage = EmpathyCopy.networkOfflineShort
            }
            aiReply = EmpathyCopy.sosAiFallback
            aiFeedbackTick += 1
        }
    }

    private static func isOfflineError(_ error: URLError) -> Bool {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }

    private static func callURL(phone: String) -> URL? {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let allowed = trimmed.filter { $0.isNumber || $0 == "+" }
        guard !allowed.isEmpty else { return nil }
        return URL(string: "tel:\(allowed)")
    }

    private static func smsURL(phone: String) -> URL? {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let allowed = trimmed.filter { $0.isNumber || $0 == "+" }
        guard !allowed.isEmpty else { return nil }
        return URL(string: "sms:\(allowed)")
    }
}
