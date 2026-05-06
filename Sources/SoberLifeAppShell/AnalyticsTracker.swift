import Foundation

public struct AnalyticsEvent: Equatable {
    public let name: String
    public let properties: [String: String]
    public let timestamp: Date

    public init(name: String, properties: [String: String], timestamp: Date = Date()) {
        self.name = name
        self.properties = properties
        self.timestamp = timestamp
    }
}

public protocol AnalyticsSink {
    func send(_ event: AnalyticsEvent)
}

public protocol AnalyticsDeduplicating {
    /// Returns true when this key is observed the first time, and records it.
    func markIfFirst(_ key: String) -> Bool
}

public struct LoggingAnalyticsSink: AnalyticsSink {
    public init() {}

    public func send(_ event: AnalyticsEvent) {
        let orderedProps = event.properties
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        print("[analytics] \(event.name) \(orderedProps)")
    }
}

public final class UserDefaultsAnalyticsDeduplicator: AnalyticsDeduplicating {
    private let defaults: UserDefaults
    private let keyPrefix: String

    public init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "soberlife.analytics.once."
    ) {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    public func markIfFirst(_ key: String) -> Bool {
        let storageKey = keyPrefix + key
        if defaults.bool(forKey: storageKey) {
            return false
        }
        defaults.set(true, forKey: storageKey)
        return true
    }
}

public final class AnalyticsTracker {
    public static let shared = AnalyticsTracker(
        sink: LoggingAnalyticsSink(),
        deduplicator: UserDefaultsAnalyticsDeduplicator()
    )

    private let sink: AnalyticsSink
    private let deduplicator: AnalyticsDeduplicating

    public init(sink: AnalyticsSink, deduplicator: AnalyticsDeduplicating) {
        self.sink = sink
        self.deduplicator = deduplicator
    }

    public func track(name: String, properties: [String: String] = [:]) {
        sink.send(AnalyticsEvent(name: name, properties: properties))
    }

    public func trackOnce(name: String, dedupeKey: String, properties: [String: String] = [:]) {
        guard deduplicator.markIfFirst(dedupeKey) else { return }
        sink.send(AnalyticsEvent(name: name, properties: properties))
    }
}

