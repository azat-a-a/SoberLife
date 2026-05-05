import Foundation

public enum SupabaseHTTPServiceError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
}

public final class HTTPSupabaseService: SupabaseService, @unchecked Sendable {
    private let baseURL: URL
    private let anonKey: String
    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    public init(baseURL: URL, anonKey: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.anonKey = anonKey
        self.session = session
        self.jsonDecoder = JSONDecoder()
        self.jsonEncoder = JSONEncoder()
    }

    public func select(table: String, filter: [String: String]) async throws -> [[String: String]] {
        var components = URLComponents(url: baseURL.appendingPathComponent("rest/v1/\(table)"), resolvingAgainstBaseURL: false)
        let queryItems = filter.map { key, value in
            URLQueryItem(name: key, value: "eq.\(value)")
        }
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else {
            throw SupabaseHTTPServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addDefaultHeaders(to: &request)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        do {
            return try jsonDecoder.decode([[String: String]].self, from: data)
        } catch {
            throw SupabaseHTTPServiceError.decodingFailed
        }
    }

    public func insert(table: String, values: [String: String]) async throws {
        let url = baseURL.appendingPathComponent("rest/v1/\(table)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addDefaultHeaders(to: &request)
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        request.httpBody = try jsonEncoder.encode(values)

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    public func invoke(function: String, payload: [String: String]) async throws -> [String: String] {
        let url = baseURL.appendingPathComponent("functions/v1/\(function)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addDefaultHeaders(to: &request)

        request.httpBody = try jsonEncoder.encode(payload)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        do {
            return try jsonDecoder.decode([String: String].self, from: data)
        } catch {
            throw SupabaseHTTPServiceError.decodingFailed
        }
    }

    private func addDefaultHeaders(to request: inout URLRequest) {
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseHTTPServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw SupabaseHTTPServiceError.httpStatus(http.statusCode)
        }
    }
}
