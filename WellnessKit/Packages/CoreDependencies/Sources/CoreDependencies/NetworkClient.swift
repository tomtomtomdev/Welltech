import Foundation
import ComposableArchitecture

// MARK: - Network Client Protocol
public struct NetworkClient {
    public var request: @Sendable (URLRequest) async throws -> Data
    public var download: @Sendable (URLRequest) async throws -> (URL, URLResponse)
    
    public init(
        request: @escaping @Sendable (URLRequest) async throws -> Data,
        download: @escaping @Sendable (URLRequest) async throws -> (URL, URLResponse)
    ) {
        self.request = request
        self.download = download
    }
}

// MARK: - API Error Types
public enum APIError: Error, Equatable, Sendable {
    case invalidURL
    case noData
    case decodingError(String)
    case networkError(Int)
    case serverError(String)
    case unknownError(String)
    
    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .networkError(let code):
            return "Network error: \(code)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - API Response Wrapper
public struct APIResponse<T: Codable & Sendable>: Codable, Sendable {
    public let data: T?
    public let message: String?
    public let success: Bool
    
    public init(data: T?, message: String?, success: Bool) {
        self.data = data
        self.message = message
        self.success = success
    }
}

// MARK: - HTTP Method
public enum HTTPMethod: String, Sendable {
    case GET, POST, PUT, DELETE, PATCH
}

// MARK: - Request Builder
public struct APIRequest {
    public let url: URL
    public let method: HTTPMethod
    public let headers: [String: String]
    public let body: Data?
    
    public init(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }
    
    public var urlRequest: URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        return request
    }
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var networkClient: NetworkClient {
        get { self[NetworkClient.self] }
        set { self[NetworkClient.self] = newValue }
    }
}

// MARK: - Live Implementation
extension NetworkClient: DependencyKey {
    public static var liveValue: NetworkClient {
        let session = URLSession.shared
        
        return NetworkClient(
            request: { request in
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.unknownError("Invalid response type")
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw APIError.networkError(httpResponse.statusCode)
                }
                
                return data
            },
            download: { request in
                let (url, response) = try await session.download(for: request)
                return (url, response)
            }
        )
    }
}

// MARK: - Mock Implementation
extension NetworkClient {
    public static var mockValue: NetworkClient {
        NetworkClient(
            request: { _ in
                throw APIError.noData
            },
            download: { _ in
                throw APIError.noData
            }
        )
    }
}
