import SwiftUI
import ComposableArchitecture
import CoreDependencies

@Reducer
struct AppFeature {
    struct State: Equatable {
        var isLoggingIn = false
        var isLoggedIn = false
        var userName: String?
    }
    
    enum Action {
        case loginButtonTapped
        case logoutButtonTapped
        case loginResponse(Result<User, Error>)
        case appLaunched
    }
    
    @Dependency(\.dateClient) var dateClient
    @Dependency(\.analyticsClient) var analyticsClient
    @Dependency(\.loggerClient) var loggerClient
    @Dependency(\.continuousClock) var clock
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appLaunched:
                // Track app launch
                return .run { send in
                    await analyticsClient.track(.appLaunched)
                }
            case .loginButtonTapped:
                state.isLoggingIn = true
                
                // Track analytics event
                Task {
                    await analyticsClient.track(.login(method: "demo"))
                    await loggerClient.info("App", "Demo login started", [:])
                }
                
                // Simulate login delay
                return .run { send in
                    try await clock.sleep(for: .seconds(2))
                    let mockUser = User(id: "123", name: "Demo User", email: "demo@welltech.com")
                    await send(.loginResponse(.success(mockUser)))
                }
                
            case .loginResponse(.success(let user)):
                state.isLoggingIn = false
                state.isLoggedIn = true
                state.userName = user.name
                
                Task {
                    await analyticsClient.setUserId(user.id)
                    await analyticsClient.setUserProperty(.hasCompletedOnboarding)
                    await loggerClient.info("App", "Demo login completed for user: \(user.name)", [:])
                }
                return .none
                
            case .loginResponse(.failure(let error)):
                state.isLoggingIn = false
                Task {
                    await loggerClient.error("App", "Login failed: \(error.localizedDescription)", [:])
                }
                return .none
                
            case .logoutButtonTapped:
                state.isLoggedIn = false
                state.userName = nil
                
                Task {
                    await analyticsClient.track(.logout())
                    await analyticsClient.reset()
                    await loggerClient.info("App", "Demo logout completed", [:])
                }
                return .none
            }
        }
    }
}

// Mock User model
struct User: Codable, Equatable {
    let id: String
    let name: String
    let email: String
}

struct ContentView: View {
    @State var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                VStack(spacing: 24) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .padding(.top, 40)
                    
                    Text("WellnessKit")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Multi-App Fitness Platform SDK")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if viewStore.isLoggingIn {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Logging in...")
                                .font(.headline)
                        }
                    } else if viewStore.isLoggedIn {
                        VStack(spacing: 16) {
                            Text("Welcome, \(viewStore.userName ?? "User")!")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("You are successfully logged into WellnessKit")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                viewStore.send(.logoutButtonTapped)
                            }) {
                                Text("Logout")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Text("Welcome to WellnessKit Demo")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("This demo showcases the WellnessKit platform SDK with TCA architecture, modular design, and comprehensive testing.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                viewStore.send(.loginButtonTapped)
                            }) {
                                HStack {
                                    Text("Login to Demo")
                                        .font(.headline)
                                    Image(systemName: "arrow.right.circle")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text("Built with ❤️ using:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Text("TCA")
                            Text("•")
                            Text("SwiftUI")
                            Text("•")
                            Text("Swift Testing")
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                }
                .navigationTitle("WellnessKit")
            }
            .task {
                // App launch is handled automatically in reducer
            }
        }
    }
}


