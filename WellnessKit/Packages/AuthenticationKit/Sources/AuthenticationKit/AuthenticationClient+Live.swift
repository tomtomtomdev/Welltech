import Foundation
import ComposableArchitecture
import CoreDependencies

// MARK: - Live Implementation
extension AuthenticationClient: DependencyKey {
    public static var liveValue: AuthenticationClient {
        return AuthenticationClient(
            login: { credentials in
                // Simulate API call with delay
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                // Mock authentication - in real app, this would call your backend
                if credentials.email == "test@example.com" && credentials.password == "password" {
                    let user = User(
                        id: "12345",
                        email: credentials.email,
                        name: "Test User",
                        isPremium: false,
                        createdAt: Date()
                    )
                    
                    return AuthToken(
                        token: "mock_jwt_token_12345",
                        refreshToken: "mock_refresh_token_67890",
                        expiresAt: Date().addingTimeInterval(3600), // 1 hour
                        user: user
                    )
                } else {
                    throw AuthenticationError.invalidCredentials
                }
            },
            
            loginWithSocial: { provider, token in
                // Simulate social auth API call
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                let user = User(
                    id: UUID().uuidString,
                    email: "user@\(provider.rawValue).com",
                    name: "\(provider.displayName) User",
                    isPremium: false,
                    createdAt: Date()
                )
                
                return AuthToken(
                    token: "social_token_\(provider.rawValue)_12345",
                    refreshToken: "social_refresh_\(provider.rawValue)_67890",
                    expiresAt: Date().addingTimeInterval(3600),
                    user: user
                )
            },
            
            logout: {
                // Simulate logout API call
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                // In real app, this would invalidate the token on the server
            },
            
            refreshToken: { refreshToken in
                // Simulate token refresh
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // In real app, this would validate and refresh the token
                let user = User(
                    id: "12345",
                    email: "test@example.com",
                    name: "Test User",
                    isPremium: false,
                    createdAt: Date()
                )
                
                return AuthToken(
                    token: "refreshed_jwt_token_12345",
                    refreshToken: "new_refresh_token_67890",
                    expiresAt: Date().addingTimeInterval(3600),
                    user: user
                )
            },
            
            signUp: { credentials, password in
                // Simulate sign up API call
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                // Validate email format
                let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
                let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
                
                guard emailPredicate.evaluate(with: credentials.email) else {
                    throw AuthenticationError.invalidEmail
                }
                
                guard password.count >= 8 else {
                    throw AuthenticationError.weakPassword
                }
                
                let user = User(
                    id: UUID().uuidString,
                    email: credentials.email,
                    name: credentials.email.components(separatedBy: "@").first ?? "New User",
                    isPremium: false,
                    createdAt: Date()
                )
                
                return user
            },
            
            resetPassword: { email in
                // Simulate password reset API call
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                // In real app, this would send a password reset email
            },
            
            getCurrentUser: {
                // Simulate getting current user from token validation
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // In real app, this would validate stored token and return user
                // For demo, return nil (user needs to login again)
                return nil
            },
            
            updateProfile: { user in
                // Simulate profile update API call
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                // In real app, this would update user profile on server
                return User(
                    id: user.id,
                    email: user.email,
                    name: user.name,
                    avatarURL: user.avatarURL,
                    isPremium: user.isPremium,
                    createdAt: user.createdAt
                )
            },
            
            deleteAccount: { password in
                // Simulate account deletion API call
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                // In real app, this would delete all user data
            },
            
            isTokenValid: {
                // Simulate token validation without throwing
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                
                // In real app, this would check if stored token is still valid
                return false // Demo: token is invalid
            }
        )
    }
}
