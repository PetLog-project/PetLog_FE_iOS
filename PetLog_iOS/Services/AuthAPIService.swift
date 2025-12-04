//
//  AuthAPIService.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 11/02/25.
//

import Foundation

// MARK: - Auth API Endpoints (명세서 기준)
enum AuthEndpoint {
    case login
    case refreshToken
    case withdraw
    
    var path: String {
        switch self {
        case .login:
            return "/api/auth/login"
        case .refreshToken:
            return "/api/auth/refresh"
        case .withdraw:
            return "/api/withdraw"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .refreshToken:
            return .post
        case .withdraw:
            return .delete
        }
    }
}

// MARK: - Auth Request Models
struct LoginRequest: Encodable {
    let providerId: String  // 카카오 서버에서 발급받은 인가 코드
    let name: String?
    let email: String?
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

// MARK: - Auth Response Models
struct LoginResponse: Decodable {
    let code: Int
    let message: String
    let data: TokenData
}

struct TokenData: Decodable {
    let accessToken: String
    let refreshToken: String
}

struct RefreshTokenResponse: Decodable {
    let code: Int
    let message: String
    let data: AccessTokenData
}

struct AccessTokenData: Decodable {
    let accessToken: String
}

struct WithdrawResponse: Decodable {
    let code: Int
    let message: String
}

// MARK: - Auth API Service
class AuthAPIService {
    static let shared = AuthAPIService()
    
    private let client = APIClient.shared
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "accessToken") }
        set { 
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "accessToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "accessToken")
            }
        }
    }
    private var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "refreshToken") }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "refreshToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "refreshToken")
            }
        }
    }
    
    private init() {}
    
    // MARK: - Login (명세서: POST /api/auth/login)
    func login(providerId: String, name: String?, email: String?) async throws -> TokenData {
        let request = LoginRequest(
            providerId: providerId,
            name: name,
            email: email
        )
        
        let response: LoginResponse = try await makeAuthRequest(
            endpoint: AuthEndpoint.login,
            body: request
        )
        
        // Save tokens
        accessToken = response.data.accessToken
        refreshToken = response.data.refreshToken
        
        return response.data
    }
    
    // MARK: - Refresh Token (명세서: POST /api/auth/refresh)
    func refreshAccessToken() async throws -> String {
        guard let token = refreshToken else {
            throw APIError.serverError(statusCode: 401, message: "리프레시 토큰이 없습니다.")
        }
        
        let request = RefreshTokenRequest(refreshToken: token)
        let response: RefreshTokenResponse = try await makeAuthRequestWithAuth(
            endpoint: AuthEndpoint.refreshToken,
            token: accessToken ?? "",
            body: request
        )
        
        // Update access token
        accessToken = response.data.accessToken
        
        return response.data.accessToken
    }
    
    // MARK: - Withdraw (명세서: DELETE /api/withdraw)
    func withdraw() async throws {
        guard let token = accessToken else {
            throw APIError.serverError(statusCode: 401, message: "액세스 토큰이 없습니다.")
        }
        
        _ = try await makeAuthRequestWithAuth(endpoint: .withdraw, token: token) as WithdrawResponse
        logout()
    }

    // MARK: - Logout
    func logout() {
        accessToken = nil
        refreshToken = nil
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "groupId")
    }
    
    // MARK: - Private Helper Methods
    private func makeAuthRequest<T: Decodable>(
        endpoint: AuthEndpoint,
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: APIConfig.baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }
        // DEBUG: Log request for troubleshooting
        #if DEBUG
        print("[AuthAPI] Request: \(request.httpMethod ?? "") \(url.absoluteString)")
        #endif
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            // Map low-level network errors for clearer messaging
            if let urlError = error as? URLError {
                throw APIError.networkError(urlError)
            }
            throw error
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // DEBUG: Log response for debugging
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[AuthAPI] Response: \(jsonString)")
        }
        #endif
        
        if httpResponse.statusCode >= 400 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    private func makeAuthRequestWithAuth<T: Decodable>(
        endpoint: AuthEndpoint,
        token: String,
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: APIConfig.baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }
        // DEBUG: Log request for troubleshooting
        #if DEBUG
        print("[AuthAPI] Auth Request: \(request.httpMethod ?? "") \(url.absoluteString)")
        #endif
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            if let urlError = error as? URLError {
                throw APIError.networkError(urlError)
            }
            throw error
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode >= 400 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
