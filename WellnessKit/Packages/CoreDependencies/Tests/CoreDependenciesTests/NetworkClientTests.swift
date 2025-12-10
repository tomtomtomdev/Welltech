import Foundation
import Testing
import ComposableArchitecture
@testable import CoreDependencies

@Suite("NetworkClient Tests")
struct NetworkClientTests {
    @Test("NetworkClient should handle successful requests")
    func successfulRequest() async throws {
        let testData = "test data".data(using: .utf8)!
        let client = NetworkClient(
            request: { _ in testData },
            download: { _ in
                let tempURL = URL(fileURLWithPath: "/tmp/test")
                try testData.write(to: tempURL)
                return (tempURL, URLResponse())
            }
        )
        
        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)
        
        let result = try await client.request(request)
        #expect(String(data: result, encoding: .utf8) == "test data")
        
        let (downloadedURL, response) = try await client.download(request)
        #expect(response is URLResponse)
        #expect(downloadedURL.lastPathComponent == "test")
    }
    
    @Test("NetworkClient should handle 404 errors")
    func networkError() async throws {
        let client = NetworkClient.liveValue
        
        // Create a request that will return a 404
        let url = URL(string: "https://httpbin.org/status/404")!
        let request = URLRequest(url: url)
        
        await #expect(throws: APIError.self) {
            try await client.request(request)
        }
    }
    
    @Test("NetworkClient should handle invalid URLs")
    func invalidURL() async throws {
        let client = NetworkClient.mockValue
        
        let request = URLRequest(url: URL(string: "not-a-valid-url")!)
        
        await #expect(throws: Error.self) {
            try await client.request(request)
        }
    }
    
    @Test("APIRequest should create proper URLRequest")
    func apiRequestCreation() throws {
        let url = URL(string: "https://api.example.com/test")!
        let apiRequest = APIRequest(
            url: url,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: "test body".data(using: .utf8)
        )
        
        let urlRequest = apiRequest.urlRequest
        
        #expect(urlRequest.url == url)
        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.allHTTPHeaderFields?["Content-Type"] == "application/json")
        #expect(urlRequest.httpBody == "test body".data(using: .utf8))
    }
    
    @Test("APIError should have correct descriptions")
    func apiErrorDescriptions() {
        #expect(APIError.invalidURL.localizedDescription == "Invalid URL")
        #expect(APIError.noData.localizedDescription == "No data received")
        #expect(APIError.decodingError("test").localizedDescription == "Decoding error: test")
        #expect(APIError.networkError(404).localizedDescription == "Network error: 404")
        #expect(APIError.serverError("test").localizedDescription == "Server error: test")
        #expect(APIError.unknownError("test").localizedDescription == "Unknown error: test")
    }
    
    @Test("APIResponse should encode and decode correctly")
    func apiResponseEncoding() throws {
        let response = APIResponse<String>(
            data: "test data",
            message: "Success",
            success: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        
        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(APIResponse<String>.self, from: data)
        
        #expect(decodedResponse.data == "test data")
        #expect(decodedResponse.message == "Success")
        #expect(decodedResponse.success == true)
    }
    
    @Test("Dependency injection should work correctly")
    func dependencyInjection() async throws {
        let testClient = NetworkClient(
            request: { _ in "mock data".data(using: .utf8)! },
            download: { _ in
                let tempURL = URL(fileURLWithPath: "/tmp/test")
                try "mock data".data(using: .utf8)!.write(to: tempURL)
                return (tempURL, URLResponse())
            }
        )
        
        await withDependencies {
            $0.networkClient = testClient
        } operation: {
            let url = URL(string: "https://api.example.com/test")!
            let request = URLRequest(url: url)
            
            let result = try await DependencyValues().networkClient.request(request)
            #expect(String(data: result, encoding: .utf8) == "mock data")
        }
    }
}
