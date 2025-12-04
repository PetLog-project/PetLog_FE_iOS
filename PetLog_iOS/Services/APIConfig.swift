import Foundation

// MARK: - API Configuration
enum APIConfig {
    // Prefer Info.plist override via `API_BASE_URL`. Fallbacks for sim/device.
    static let baseURL: String = {
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           url.isEmpty == false,
           url.contains("${") == false { // ignore unresolved placeholders
            return url
        }
        // Default to dev deployment site
        return "https://dev.petlog.site"
    }()
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
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Endpoint (명세서 기준)
enum APIEndpoint {
    // Group Management
    case getMyGroups
    case createGroup
    case joinGroup
    case leaveGroup(groupId: String)
    case getInviteCode(groupId: String)
    
    // Pet Information
    case getPetInfo(groupId: String)
    case updatePetInfo(groupId: String)
    
    // Activity Logs
    case createFeedingLog(groupId: String)
    case createWateringLog(groupId: String)
    case createPoopLog(groupId: String)
    
    // Diary
    case createDiary(groupId: String)
    case getDiaryList(groupId: String)
    case getDiaryDetail(groupId: String, diaryId: String)
    case updateDiary(groupId: String, diaryId: String)
    case deleteDiary(groupId: String, diaryId: String)
    
    // Schedule
    case getSchedule(groupId: String, date: String)
    
    // Notes
    case getNote(groupId: String)
    case updateNote(groupId: String)
    
    // Notification
    case setNotificationPreference
    case getNotificationPreference
    case savePushToken
    case deletePushToken
    
    // S3
    case getPresignedUrls
    
    var path: String {
        switch self {
        // Group
        case .getMyGroups:
            return "/api/groups/my"
        case .createGroup:
            return "/api/groups"
        case .joinGroup:
            return "/api/groups/join"
        case .leaveGroup(let groupId):
            return "/api/groups/\(groupId)/leave"
        case .getInviteCode(let groupId):
            return "/api/groups/\(groupId)/invite"
        
        // Pet
        case .getPetInfo(let groupId):
            return "/api/groups/\(groupId)/pet"
        case .updatePetInfo(let groupId):
            return "/api/groups/\(groupId)/pet"
        
        // Activity
        case .createFeedingLog(let groupId):
            return "/api/groups/\(groupId)/pet/feeding"
        case .createWateringLog(let groupId):
            return "/api/groups/\(groupId)/pet/watering"
        case .createPoopLog(let groupId):
            return "/api/groups/\(groupId)/pet/poop"
        
        // Diary
        case .createDiary(let groupId):
            return "/api/groups/\(groupId)/diary"
        case .getDiaryList(let groupId):
            return "/api/groups/\(groupId)/diary"
        case .getDiaryDetail(let groupId, let diaryId):
            return "/api/groups/\(groupId)/diary/\(diaryId)"
        case .updateDiary(let groupId, let diaryId):
            return "/api/groups/\(groupId)/diary/\(diaryId)"
        case .deleteDiary(let groupId, let diaryId):
            return "/api/groups/\(groupId)/diary/\(diaryId)"
        
        // Schedule
        case .getSchedule(let groupId, let date):
            return "/api/groups/\(groupId)/schedule?date=\(date)"
        
        // Notes
        case .getNote(let groupId):
            return "/api/groups/\(groupId)/note"
        case .updateNote(let groupId):
            return "/api/groups/\(groupId)/note"
        
        // Notification
        case .setNotificationPreference:
            return "/api/notification"
        case .getNotificationPreference:
            return "/api/notification"
        case .savePushToken:
            return "/api/notification/token"
        case .deletePushToken:
            return "/api/notification/token"
        
        // S3
        case .getPresignedUrls:
            return "/api/s3/presigned-urls"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getMyGroups, .getPetInfo, .getDiaryList, .getDiaryDetail, .getSchedule, .getNote, .getNotificationPreference, .getInviteCode:
            return .get
        
        case .createGroup, .joinGroup, .createFeedingLog, .createWateringLog, .createPoopLog, .createDiary, .savePushToken, .getPresignedUrls:
            return .post
        
        case .updatePetInfo, .updateDiary, .updateNote, .setNotificationPreference:
            return .patch
        
        case .leaveGroup, .deleteDiary, .deletePushToken:
            return .delete
        }
    }
}
