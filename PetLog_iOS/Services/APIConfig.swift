import Foundation

// MARK: - API Configuration
enum APIConfig {
    #if targetEnvironment(simulator)
    static let baseURL = "http://localhost:8080"
    #else
    static let baseURL = "http://192.168.0.114:8080" // Mac's IP address
    #endif
    static let timeoutInterval: TimeInterval = 30
}

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(statusCode: Int, message: String)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .decodingError(let error):
            return "데이터 파싱 오류: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "서버 오류 (\(statusCode)): \(message)"
        case .noData:
            return "데이터가 없습니다."
        }
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - API Endpoint
enum APIEndpoint {
    case getMyGroup
    case createGroup
    case joinGroup
    case updateProfile
    case getNotes
    case updateNotes
    case deleteNotes
    case createFeedingLog
    case createWateringLog
    case createPoopLog
    
    var path: String {
        switch self {
        case .getMyGroup:
            return "/api/groups/my"
        case .createGroup:
            return "/api/groups"
        case .joinGroup:
            return "/api/groups/join"
        case .updateProfile:
            return "/api/groups/my"
        case .getNotes:
            return "/api/groups/my/notes"
        case .updateNotes:
            return "/api/groups/my/notes"
        case .deleteNotes:
            return "/api/groups/my/notes"
        case .createFeedingLog:
            return "/api/logs/feeding"
        case .createWateringLog:
            return "/api/logs/watering"
        case .createPoopLog:
            return "/api/logs/poop"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getMyGroup, .getNotes:
            return .get
        case .createGroup, .joinGroup, .createFeedingLog, .createWateringLog, .createPoopLog:
            return .post
        case .updateProfile, .updateNotes:
            return .put
        case .deleteNotes:
            return .delete
        }
    }
}
