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

    // MARK: - Authenticated REST (PostgREST + user JWT for RLS)

    public func restSelectRaw(
        table: String,
        queryItems: [URLQueryItem],
        bearerToken: String
    ) async throws -> Data {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("rest/v1/\(table)"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else {
            throw SupabaseHTTPServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addUserRestHeaders(to: &request, bearerToken: bearerToken)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return data
    }

    public func restInsert(
        table: String,
        jsonBody: Data,
        bearerToken: String,
        returnRepresentation: Bool
    ) async throws -> Data {
        let url = baseURL.appendingPathComponent("rest/v1/\(table)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addUserRestHeaders(to: &request, bearerToken: bearerToken)
        request.setValue(
            returnRepresentation ? "return=representation" : "return=minimal",
            forHTTPHeaderField: "Prefer"
        )
        request.httpBody = jsonBody

        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return data
    }

    public func restPatch(
        table: String,
        filter: [String: String],
        jsonBody: Data,
        bearerToken: String
    ) async throws {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("rest/v1/\(table)"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = filter.map { URLQueryItem(name: $0.key, value: "eq.\($0.value)") }

        guard let url = components?.url else {
            throw SupabaseHTTPServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        addUserRestHeaders(to: &request, bearerToken: bearerToken)
        request.httpBody = jsonBody

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    private func addDefaultHeaders(to request: inout URLRequest) {
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }

    private func addUserRestHeaders(to request: inout URLRequest, bearerToken: String) {
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
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
