//
//  AuthAPIService.swift
//  PetLog_iOS
//
//  Created by Agent on 11/02/25.
//

import Foundation

// MARK: - Auth API Endpoints
enum AuthEndpoint {
    case login
    case register
    case verify(token: String)
    case getCurrentUser
    case kakaoLogin
    case refresh
    case withdraw
    
    var path: String {
        switch self {
        case .login:
            return "/api/auth/login"
        case .register:
            return "/api/auth/register"
        case .verify(let token):
            return "/api/auth/verify?token=\(token)"
        case .getCurrentUser:
            return "/api/auth/me"
        case .kakaoLogin:
            return "/api/auth/login/kakao"
        case .refresh:
            return "/api/auth/refresh"
        case .withdraw:
            return "/api/auth/withdraw"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .register, .kakaoLogin:
            return .post
        case .verify, .getCurrentUser, .refresh:
            return .get
        case .withdraw:
            return .delete
        }
    }
}

// MARK: - Auth Request Models
struct LoginRequest: Encodable {
    let oauthProvider: String
    let oauthId: String
    let email: String?
}

struct RegisterRequest: Encodable {
    let oauthProvider: String
    let oauthId: String
    let email: String?
    let nickname: String?
    let profileImageUrl: String?
}

// MARK: - Auth Response Models
struct LoginResponse: Decodable {
    let statusCode: Int
    let message: String
    let data: LoginData
}

struct LoginData: Decodable {
    let userId: String
    let token: String
    let nickname: String?
    let email: String?
    let profileImageUrl: String?
}

struct VerifyResponse: Decodable {
    let statusCode: Int
    let message: String
    let data: UserData
}

struct UserData: Decodable {
    let userId: String
    let oauthProvider: String
    let nickname: String?
    let email: String?
    let profileImageUrl: String?
}

struct UserResponse: Decodable {
    let statusCode: Int
    let message: String
    let data: UserDetailData
}

struct UserDetailData: Decodable {
    let userId: String
    let oauthProvider: String
    let nickname: String?
    let email: String?
    let profileImageUrl: String?
    let groupId: String?
    let createdAt: String?
}

// MARK: - Auth API Service
class AuthAPIService {
    static let shared = AuthAPIService()
    
    private let client = APIClient.shared
    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
        set { 
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "authToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "authToken")
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
    
    // MARK: - Login
    func login(oauthProvider: String, oauthId: String, email: String?) async throws -> LoginData {
        let request = LoginRequest(
            oauthProvider: oauthProvider,
            oauthId: oauthId,
            email: email
        )
        
        let response: LoginResponse = try await makeAuthRequest(
            endpoint: AuthEndpoint.login,
            body: request
        )
        
        // Save token
        authToken = response.data.token
        
        return response.data
    }
    
    // MARK: - Register
    func register(
        oauthProvider: String,
        oauthId: String,
        email: String?,
        nickname: String?,
        profileImageUrl: String?
    ) async throws -> LoginData {
        let request = RegisterRequest(
            oauthProvider: oauthProvider,
            oauthId: oauthId,
            email: email,
            nickname: nickname,
            profileImageUrl: profileImageUrl
        )
        
        let response: LoginResponse = try await makeAuthRequest(
            endpoint: AuthEndpoint.register,
            body: request
        )
        
        // Save token
        authToken = response.data.token
        
        return response.data
    }
    
    // MARK: - Verify Token
    func verifyToken(_ token: String) async throws -> UserData {
        let response: VerifyResponse = try await makeAuthRequest(
            endpoint: AuthEndpoint.verify(token: token)
        )
        
        return response.data
    }
    
    // MARK: - Get Current User
    func getCurrentUser() async throws -> UserDetailData {
        guard let token = authToken else {
            throw APIError.serverError(statusCode: 401, message: "인증 토큰이 없습니다.")
        }
        
        let response: UserResponse = try await makeAuthRequestWithAuth(
            endpoint: AuthEndpoint.getCurrentUser,
            token: token
        )
        
        return response.data
    }
    
    // MARK: - Kakao Login (Test API)
    struct KakaoLoginRequest: Encodable { let accessCode: String }
    struct TokenPairResponse: Decodable { let statusCode: Int; let message: String; let data: TokenPairData }
    struct TokenPairData: Decodable { let accessToken: String; let refreshToken: String }
    struct AccessTokenResponse: Decodable { let statusCode: Int; let message: String; let data: AccessTokenData }
    struct AccessTokenData: Decodable { let accessToken: String }

    func kakaoLogin(accessCode: String) async throws {
        let body = KakaoLoginRequest(accessCode: accessCode)
        let res: TokenPairResponse = try await makeAuthRequest(endpoint: .kakaoLogin, body: body)
        authToken = res.data.accessToken
        refreshToken = res.data.refreshToken
    }

    func refreshAccessToken() async throws {
        guard let token = authToken ?? refreshToken else {
            throw APIError.serverError(statusCode: 401, message: "인증 토큰이 없습니다.")
        }
        let res: AccessTokenResponse = try await makeAuthRequestWithAuth(endpoint: .refresh, token: token)
        authToken = res.data.accessToken
    }

    func withdraw() async throws {
        guard let token = authToken else {
            throw APIError.serverError(statusCode: 401, message: "인증 토큰이 없습니다.")
        }
        struct Simple: Decodable { let statusCode: Int; let message: String }
        _ = try await makeAuthRequestWithAuth(endpoint: .withdraw, token: token) as Simple
        logout()
    }

    // MARK: - Logout
    func logout() {
        authToken = nil
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
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
