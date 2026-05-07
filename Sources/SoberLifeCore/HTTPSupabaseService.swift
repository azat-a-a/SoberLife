import Foundation

public enum SupabaseHTTPServiceError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    /// Auth response included a user but no `access_token` (typical when email confirmation is required).
    case authPendingEmailConfirmation
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

    // MARK: - Supabase Auth (email / password)

    public func authSignIn(email: String, password: String) async throws -> SupabasePasswordAuthResult {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("auth/v1/token"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        guard let url = components?.url else {
            throw SupabaseHTTPServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addDefaultHeaders(to: &request)
        request.httpBody = try jsonEncoder.encode(AuthEmailPasswordBody(email: email, password: password))

        let (data, response) = try await session.data(for: request)
        try validateAuth(response: response)
        return try decodeAuthSession(data: data)
    }

    public func authSignUp(email: String, password: String) async throws -> SupabasePasswordAuthResult {
        let url = baseURL.appendingPathComponent("auth/v1/signup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addDefaultHeaders(to: &request)
        request.httpBody = try jsonEncoder.encode(AuthEmailPasswordBody(email: email, password: password))

        let (data, response) = try await session.data(for: request)
        try validateAuth(response: response)
        return try decodeAuthSession(data: data)
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

    public func restRPCVoid(
        function: String,
        jsonBody: Data,
        bearerToken: String
    ) async throws {
        let url = baseURL.appendingPathComponent("rest/v1/rpc/\(function)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addUserRestHeaders(to: &request, bearerToken: bearerToken)
        request.httpBody = jsonBody

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    public func restRPC(
        function: String,
        jsonBody: Data,
        bearerToken: String
    ) async throws -> Data {
        let url = baseURL.appendingPathComponent("rest/v1/rpc/\(function)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addUserRestHeaders(to: &request, bearerToken: bearerToken)
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

    /// PostgREST upsert on primary key / unique constraints (`Prefer: resolution=merge-duplicates`).
    public func restUpsertMerge(
        table: String,
        jsonBody: Data,
        bearerToken: String
    ) async throws {
        let url = baseURL.appendingPathComponent("rest/v1/\(table)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addUserRestHeaders(to: &request, bearerToken: bearerToken)
        request.setValue("return=minimal,resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
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

    private func validateAuth(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseHTTPServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw SupabaseHTTPServiceError.httpStatus(http.statusCode)
        }
    }

    private func decodeAuthSession(data: Data) throws -> SupabasePasswordAuthResult {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let dto = try decoder.decode(AuthSessionDTO.self, from: data)
            let idString = dto.user?.id ?? dto.id
            guard let idString, let userID = UUID(uuidString: idString) else {
                throw SupabaseHTTPServiceError.decodingFailed
            }
            guard let token = dto.accessToken, !token.isEmpty else {
                throw SupabaseHTTPServiceError.authPendingEmailConfirmation
            }
            return SupabasePasswordAuthResult(accessToken: token, userID: userID)
        } catch is DecodingError {
            throw SupabaseHTTPServiceError.decodingFailed
        } catch let error as SupabaseHTTPServiceError {
            throw error
        } catch {
            throw SupabaseHTTPServiceError.decodingFailed
        }
    }
}

private struct AuthEmailPasswordBody: Encodable {
    let email: String
    let password: String
}

private struct AuthSessionDTO: Decodable {
    let accessToken: String?
    let user: AuthUserDTO?
    /// Present on some sign-up responses when the user object is returned at the root without a `user` wrapper.
    let id: String?
}

private struct AuthUserDTO: Decodable {
    let id: String
}
