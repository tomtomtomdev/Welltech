import Foundation
import ComposableArchitecture
import CoreDependencies

// MARK: - Authentication Features
@Reducer
public struct AuthenticationFeature {
    public struct State: Equatable {
        public var currentUser: User?
        public var isLoading: Bool = false
        public var loginError: AuthenticationError?
        public var signUpError: AuthenticationError?
        public var resetPasswordError: AuthenticationError?
        public var updateProfileError: AuthenticationError?
        public var isAuthenticated: Bool {
            currentUser != nil
        }
        
        public init(currentUser: User? = nil) {
            self.currentUser = currentUser
        }
    }
    
    public enum Action: Sendable {
        case login(AuthCredentials)
        case loginWithSocial(AuthProvider, String)
        case loginResponse(Result<AuthToken, AuthenticationError>)
        case signUp(AuthCredentials, String)
        case signUpResponse(Result<User, AuthenticationError>)
        case logout
        case logoutResponse(Void?)
        case refreshToken
        case refreshTokenResponse(Result<AuthToken, AuthenticationError>)
        case resetPassword(String)
        case resetPasswordResponse(Result<Void, AuthenticationError>)
        case updateProfile(User)
        case updateProfileResponse(Result<User, AuthenticationError>)
        case deleteAccount(String)
        case deleteAccountResponse(Result<Void, AuthenticationError>)
        case loadCurrentUser
        case loadCurrentUserResponse(User?)
        case clearErrors
    }
    
    @Dependency(\.authenticationClient) var authenticationClient
    @Dependency(\.dateClient) var dateClient
    @Dependency(\.loggerClient) var loggerClient
    @Dependency(\.analyticsClient) var analyticsClient
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .login(let credentials):
                state.isLoading = true
                state.loginError = nil
                
                return .run { send in
                    do {
                        let token = try await authenticationClient.login(credentials)
                        await send(.loginResponse(.success(token)))
                    } catch {
                        await loggerClient.error("Auth", "Login failed: \(error.localizedDescription)", [:])
                        await send(.loginResponse(.failure(.networkError(error.localizedDescription))))
                    }
                }
                
            case .loginWithSocial(let provider, let token):
                state.isLoading = true
                state.loginError = nil
                
                return .run { send in
                    do {
                        let authToken = try await authenticationClient.loginWithSocial(provider, token)
                        await send(.loginResponse(.success(authToken)))
                    } catch {
                        await loggerClient.error("Auth", "Social login failed: \(error.localizedDescription)", [:])
                        await send(.loginResponse(.failure(.socialAuthError(error.localizedDescription))))
                    }
                }
                
            case .loginResponse(.success(let token)):
                state.isLoading = false
                state.currentUser = token.user
                state.loginError = nil

                return .run { _ in
                    await analyticsClient.setUserId(token.user.id)
                    await analyticsClient.track(.login(method: AuthProvider.email.rawValue))
                    await loggerClient.info("Auth", "User logged in: \(token.user.name)", [:])
                }
                
            case .loginResponse(.failure(let error)):
                state.isLoading = false
                state.loginError = error
                
                return .run { _ in
                    await analyticsClient.track(.login(method: "email_failed"))
                    await loggerClient.warning("Auth", "Login failed: \(error.localizedDescription)", [:])
                }
                
            case .signUp(let credentials, let password):
                state.isLoading = true
                state.signUpError = nil
                
                return .run { send in
                    do {
                        let user = try await authenticationClient.signUp(credentials, password)
                        await send(.signUpResponse(.success(user)))
                    } catch {
                        await loggerClient.error("Auth", "Sign up failed: \(error.localizedDescription)", [:])
                        await send(.signUpResponse(.failure(.networkError(error.localizedDescription))))
                    }
                }
                
            case .signUpResponse(.success(let user)):
                state.isLoading = false
                state.signUpError = nil
                
                return .run { _ in
                    await analyticsClient.track(AnalyticsEvent(
                        name: "sign_up_completed",
                        parameters: ["method": .string("email")]
                    ))
                    await loggerClient.info("Auth", "User signed up: \(user.name)", [:])
                }
                
            case .signUpResponse(.failure(let error)):
                state.isLoading = false
                state.signUpError = error
                
                return .run { _ in
                    await analyticsClient.track(AnalyticsEvent(
                        name: "sign_up_failed",
                        parameters: ["error": .string(error.errorDescription ?? "unknown")]
                    ))
                    await loggerClient.warning("Auth", "Sign up failed: \(error.localizedDescription)", [:])
                }
                
            case .logout:
                state.isLoading = true
                
                return .run { send in
                    await authenticationClient.logout()
                    await send(.logoutResponse(()))
                }
                
            case .logoutResponse:
                state.isLoading = false
                let userName = state.currentUser?.name
                state.currentUser = nil
                state.loginError = nil
                
                return .run { _ in
                    await analyticsClient.track(.logout())
                    await analyticsClient.reset()
                    if let userName = userName {
                        await loggerClient.info("Auth", "User logged out: \(userName)", [:])
                    }
                }
                
            case .refreshToken:
                return .run { send in
                    do {
                        let token = try await authenticationClient.refreshToken("dummy_refresh_token")
                        await send(.refreshTokenResponse(.success(token)))
                    } catch {
                        await loggerClient.error("Auth", "Token refresh failed: \(error.localizedDescription)", [:])
                        await send(.refreshTokenResponse(.failure(.networkError(error.localizedDescription))))
                    }
                }
                
            case .refreshTokenResponse(.success(let token)):
                state.currentUser = token.user
                
                return .run { _ in
                    await loggerClient.info("Auth", "Token refreshed for user: \(token.user.name)", [:])
                }
                
            case .refreshTokenResponse(.failure):
                // Token refresh failed, log out user
                state.currentUser = nil
                
                return .run { _ in
                    await analyticsClient.track(.logout())
                    await analyticsClient.reset()
                    await loggerClient.warning("Auth", "Token refresh failed, user logged out", [:])
                }
                
            case .resetPassword(let email):
                state.isLoading = true
                state.resetPasswordError = nil
                
                return .run { send in
                    do {
                        try await authenticationClient.resetPassword(email)
                        await send(.resetPasswordResponse(.success(())))
                    } catch {
                        await loggerClient.error("Auth", "Password reset failed: \(error.localizedDescription)", [:])
                        await send(.resetPasswordResponse(.failure(.networkError(error.localizedDescription))))
                    }
                }
                
            case .resetPasswordResponse(.success):
                state.isLoading = false
                
                return .run { _ in
                    await analyticsClient.track(AnalyticsEvent(
                        name: "password_reset_completed",
                        parameters: [:]
                    ))
                    await loggerClient.info("Auth", "Password reset completed", [:])
                }
                
            case .resetPasswordResponse(.failure(let error)):
                state.isLoading = false
                state.resetPasswordError = error
                
                return .run { _ in
                    await analyticsClient.track(AnalyticsEvent(
                        name: "password_reset_failed",
                        parameters: ["error": .string(error.errorDescription ?? "unknown")]
                    ))
                    await loggerClient.warning("Auth", "Password reset failed: \(error.localizedDescription)", [:])
                }
                
            case .updateProfile(let user):
                state.isLoading = true
                state.updateProfileError = nil
                
                return .run { send in
                    do {
                        let updatedUser = try await authenticationClient.updateProfile(user)
                        await send(.updateProfileResponse(.success(updatedUser)))
                    } catch {
                        await loggerClient.error("Auth", "Profile update failed: \(error.localizedDescription)", [:])
                        await send(.updateProfileResponse(.failure(.networkError(error.localizedDescription))))
                    }
                }
                
            case .updateProfileResponse(.success(let user)):
                state.isLoading = false
                state.currentUser = user
                state.updateProfileError = nil
                
                return .run { _ in
                    await analyticsClient.track(AnalyticsEvent(
                        name: "profile_updated",
                        parameters: [:]
                    ))
                    await loggerClient.info("Auth", "Profile updated for user: \(user.name)", [:])
                }
                
            case .updateProfileResponse(.failure(let error)):
                state.isLoading = false
                state.updateProfileError = error
                
                return .run { _ in
                    await analyticsClient.track(AnalyticsEvent(
                        name: "profile_update_failed",
                        parameters: ["error": .string(error.errorDescription ?? "unknown")]
                    ))
                    await loggerClient.warning("Auth", "Profile update failed: \(error.localizedDescription)", [:])
                }
                
            case .deleteAccount(let password):
                state.isLoading = true
                
                return .run { send in
                    do {
                        try await authenticationClient.deleteAccount(password)
                        await send(.deleteAccountResponse(.success(())))
                    } catch {
                        await loggerClient.error("Auth", "Account deletion failed: \(error.localizedDescription)", [:])
                        await send(.deleteAccountResponse(.failure(.networkError(error.localizedDescription))))
                    }
                }
                
            case .deleteAccountResponse(.success):
                state.isLoading = false
                state.currentUser = nil
                
                return .run { _ in
                    await analyticsClient.track(AnalyticsEvent(
                        name: "account_deleted",
                        parameters: [:]
                    ))
                    await analyticsClient.reset()
                    await loggerClient.info("Auth", "Account deleted", [:])
                }
                
            case .deleteAccountResponse(.failure(let error)):
                state.isLoading = false
                
                return .run { _ in
                    await analyticsClient.track(AnalyticsEvent(
                        name: "account_deletion_failed",
                        parameters: ["error": .string(error.errorDescription ?? "unknown")]
                    ))
                    await loggerClient.warning("Auth", "Account deletion failed: \(error.localizedDescription)", [:])
                }
                
            case .loadCurrentUser:
                return .run { send in
                    let user = await authenticationClient.getCurrentUser()
                    await send(.loadCurrentUserResponse(user))
                }
                
            case .loadCurrentUserResponse(let user):
                state.currentUser = user
                
                return .run { _ in
                    if let user = user {
                        await loggerClient.info("Auth", "Current user loaded: \(user.name)", [:])
                    }
                }
                
            case .clearErrors:
                state.loginError = nil
                state.signUpError = nil
                state.resetPasswordError = nil
                state.updateProfileError = nil
                
                return .none
            }
        }
    }
}
