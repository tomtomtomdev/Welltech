import Foundation
import ComposableArchitecture
import CoreDependencies

// MARK: - Authentication Models
public struct User: Codable, Equatable, Sendable {
    public let id: String
    public let email: String
    public let name: String
    public let avatarURL: URL?
    public let isPremium: Bool
    public let createdAt: Date
    
    public init(
        id: String,
        email: String,
        name: String,
        avatarURL: URL? = nil,
        isPremium: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarURL = avatarURL
        self.isPremium = isPremium
        self.createdAt = createdAt
    }
}

public struct AuthCredentials: Codable, Equatable, Sendable {
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct AuthToken: Codable, Equatable, Sendable {
    public let token: String
    public let refreshToken: String
    public let expiresAt: Date
    public let user: User
    
    public init(token: String, refreshToken: String, expiresAt: Date, user: User) {
        self.token = token
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.user = user
    }
    
    public var isValid: Bool {
        return expiresAt > Date()
    }
}

public enum AuthenticationError: LocalizedError, Equatable {
    case invalidCredentials
    case networkError(String)
    case tokenExpired
    case accountLocked
    case accountNotFound
    case invalidEmail
    case weakPassword
    case socialAuthError(String)
    case unknownError(String)
    
    public static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials),
             (.tokenExpired, .tokenExpired),
             (.accountLocked, .accountLocked),
             (.accountNotFound, .accountNotFound),
             (.invalidEmail, .invalidEmail),
             (.weakPassword, .weakPassword):
            return true
        case let (.networkError(lhsMessage), .networkError(rhsMessage)):
            return lhsMessage == rhsMessage
        case let (.socialAuthError(lhsMessage), .socialAuthError(rhsMessage)):
            return lhsMessage == rhsMessage
        case let (.unknownError(lhsMessage), .unknownError(rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let error):
            return "Network error: \(error)"
        case .tokenExpired:
            return "Authentication token has expired"
        case .accountLocked:
            return "Account has been locked"
        case .accountNotFound:
            return "Account not found"
        case .invalidEmail:
            return "Invalid email address"
        case .weakPassword:
            return "Password is too weak"
        case .socialAuthError(let message):
            return "Social authentication failed: \(message)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

public enum AuthProvider: String, CaseIterable, Sendable {
    case email = "email"
    case apple = "apple"
    case google = "google"
    case facebook = "facebook"
    case twitter = "twitter"
    
    public var displayName: String {
        switch self {
        case .email:
            return "Email"
        case .apple:
            return "Apple"
        case .google:
            return "Google"
        case .facebook:
            return "Facebook"
        case .twitter:
            return "Twitter"
        }
    }
}

// MARK: - Authentication Client Protocol
public struct AuthenticationClient {
    public var login: @Sendable (AuthCredentials) async throws -> AuthToken
    public var loginWithSocial: @Sendable (AuthProvider, String) async throws -> AuthToken
    public var logout: @Sendable () async -> Void
    public var refreshToken: @Sendable (String) async throws -> AuthToken
    public var signUp: @Sendable (AuthCredentials, String) async throws -> User
    public var resetPassword: @Sendable (String) async throws -> Void
    public var getCurrentUser: @Sendable () async -> User?
    public var updateProfile: @Sendable (User) async throws -> User
    public var deleteAccount: @Sendable (String) async throws -> Void
    public var isTokenValid: @Sendable () async -> Bool
    
    public init(
        login: @escaping @Sendable (AuthCredentials) async throws -> AuthToken,
        loginWithSocial: @escaping @Sendable (AuthProvider, String) async throws -> AuthToken,
        logout: @escaping @Sendable () async -> Void,
        refreshToken: @escaping @Sendable (String) async throws -> AuthToken,
        signUp: @escaping @Sendable (AuthCredentials, String) async throws -> User,
        resetPassword: @escaping @Sendable (String) async throws -> Void,
        getCurrentUser: @escaping @Sendable () async -> User?,
        updateProfile: @escaping @Sendable (User) async throws -> User,
        deleteAccount: @escaping @Sendable (String) async throws -> Void,
        isTokenValid: @escaping @Sendable () async -> Bool
    ) {
        self.login = login
        self.loginWithSocial = loginWithSocial
        self.logout = logout
        self.refreshToken = refreshToken
        self.signUp = signUp
        self.resetPassword = resetPassword
        self.getCurrentUser = getCurrentUser
        self.updateProfile = updateProfile
        self.deleteAccount = deleteAccount
        self.isTokenValid = isTokenValid
    }
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var authenticationClient: AuthenticationClient {
        get { self[AuthenticationClient.self] }
        set { self[AuthenticationClient.self] = newValue }
    }
}
