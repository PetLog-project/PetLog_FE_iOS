import Foundation

// MARK: - Request/Response Models
struct CreateGroupRequest: Codable {
    let imageUrl: String
    let name: String
    let age: String
    // Test API: weight is a string like "1kg"
    let weight: String
    let gender: String
    let feedingCycle: Int
    let lastFeedingTime: String
    let wateringCycle: Int
    let lastWateringTime: String
    let notice: String?
}

struct SimpleResponse: Codable { let statusCode: Int; let message: String }

struct JoinGroupRequest: Codable {
    let joinCode: String
}

struct JoinGroupResponse: Codable {
    let statusCode: Int
    let message: String
}

struct UpdateProfileRequest: Codable {
    let imageUrl: String?
    let name: String?
    let age: String?
    let weight: String?
    let gender: String?
    let feedingCycle: Int?
    let lastFeedingTime: String?
    let wateringCycle: Int?
    let lastWateringTime: String?
    let notice: String?
}

struct UpdateProfileResponse: Codable {
    let statusCode: Int
    let message: String
}

struct ReferenceNote: Codable {
    let id: String
    let groupId: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
}

struct UpdateNotesRequest: Codable {
    let content: String
}

struct CreateActivityLogRequest: Codable {
    let checkerName: String
    let memo: String?
}

struct ActivityLogResponse: Codable {
    let id: String
    let groupId: String
    let checkerName: String
    let memo: String?
    let timestamp: String
}

// MARK: - PetLog API Service
class PetLogAPIService {
    static let shared = PetLogAPIService()
    private let client = APIClient.shared
    
    private init() {}
    
    // MARK: - Group Management
    
    /// Get my group's pet information
    func getMyGroup() async throws -> HomeResponse {
        // 1) Get current user for groupId
        let me = try await AuthAPIService.shared.getCurrentUser()
        guard let groupId = me.groupId else {
            throw APIError.serverError(statusCode: 404, message: "가입한 그룹이 없습니다.")
        }
        // 2) Fetch pet info
        struct Envelope<T: Decodable>: Decodable { let statusCode:Int; let message:String; let data:T }
        struct PetProfileByGroup: Decodable { let imageUrl:String; let name:String; let age:String; let weight:String; let gender:String }
        struct FeedingDTO: Decodable { let feedingCycle:Int; let lastFeedingTime:String; let lastCheckerName:String; let lastMemo:String? }
        struct WateringDTO: Decodable { let wateringCycle:Int; let lastWateringTime:String; let lastCheckerName:String; let lastMemo:String? }
        struct PoopDTO: Decodable { let todayPoopCount:Int; let lastCheckerName:String; let lastMemo:String? }
        struct PetInfoByGroupDTO: Decodable { let profile:PetProfileByGroup; let feeding:FeedingDTO; let watering:WateringDTO; let poop:PoopDTO }

        let path = "/api/groups/\(groupId)/pet"
        guard let url = URL(string: APIConfig.baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500, message: msg)
        }
        let decoded = try JSONDecoder().decode(Envelope<PetInfoByGroupDTO>.self, from: data)

        // 3) Fetch invite code (joinCode)
        let joinCode = try await getInviteCode(groupId: groupId)

        // 4) Map to HomeResponse
        func parseTime(_ s: String) -> Date {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm"
            return df.date(from: s) ?? Date()
        }
        func parseWeight(_ s: String) -> Double {
            let norm = s.lowercased().replacingOccurrences(of: "kg", with: "").trimmingCharacters(in: .whitespaces)
            return Double(norm) ?? 0
        }
        let prof = decoded.data.profile
        let homeProfile = Profile(imageUrl: prof.imageUrl, name: prof.name, age: prof.age, weight: parseWeight(prof.weight), gender: Gender(rawValue: prof.gender) ?? .female)
        let feed = decoded.data.feeding
        let homeFeeding = Feeding(feedingCycle: feed.feedingCycle, lastFeedingTime: parseTime(feed.lastFeedingTime), lastCheckerName: feed.lastCheckerName, lastMemo: feed.lastMemo ?? "")
        let water = decoded.data.watering
        let homeWater = Watering(wateringCycle: water.wateringCycle, lastWateringTime: parseTime(water.lastWateringTime), lastCheckerName: water.lastCheckerName, lastMemo: water.lastMemo ?? "")
        let poop = decoded.data.poop
        let homePoop = Poop(todayPoopCount: poop.todayPoopCount, lastCheckerName: poop.lastCheckerName, lastMemo: poop.lastMemo ?? "")
        let homeData = HomeData(profile: homeProfile, feeding: homeFeeding, watering: homeWater, poop: homePoop, joinCode: joinCode)
        return HomeResponse(statusCode: decoded.statusCode, message: decoded.message, data: homeData)
    }
    
    /// Create a new group
    func createGroup(request: CreateGroupRequest) async throws -> SimpleResponse {
        return try await client.request(endpoint: .createGroup, body: request)
    }
    
    /// Join existing group with code
    func joinGroup(joinCode: String) async throws -> JoinGroupResponse {
        let request = JoinGroupRequest(joinCode: joinCode)
        return try await client.request(endpoint: .joinGroup, body: request)
    }
    
    /// Update profile (PATCH /api/groups/{groupId}/pet)
    func updateProfile(request: UpdateProfileRequest) async throws -> UpdateProfileResponse {
        let me = try await AuthAPIService.shared.getCurrentUser()
        guard let groupId = me.groupId else {
            throw APIError.serverError(statusCode: 404, message: "가입한 그룹이 없습니다.")
        }
        guard let url = URL(string: APIConfig.baseURL + "/api/groups/\(groupId)/pet") else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "authToken") { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let encoder = JSONEncoder()
        req.httpBody = try encoder.encode(request)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode < 400 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: (resp as? HTTPURLResponse)?.statusCode ?? 500, message: msg)
        }
        return try JSONDecoder().decode(UpdateProfileResponse.self, from: data)
    }
    
    // MARK: - Notes Management (per test API)
    struct NoteEnvelope: Codable { let statusCode:Int; let message:String; let data: NoteData }
    struct NoteData: Codable { let note: String? }
    struct PatchNoteRequestBody: Codable { let note: String? }

    /// Get reference note text for current group
    func getNotes() async throws -> String? {
        let me = try await AuthAPIService.shared.getCurrentUser()
        guard let groupId = me.groupId else { throw APIError.serverError(statusCode: 404, message: "가입한 그룹이 없습니다.") }
        guard let url = URL(string: APIConfig.baseURL + "/api/groups/\(groupId)/note") else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "authToken") { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode < 400 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: (resp as? HTTPURLResponse)?.statusCode ?? 500, message: msg)
        }
        let decoded = try JSONDecoder().decode(NoteEnvelope.self, from: data)
        return decoded.data.note
    }

    /// Create or update note text (send null to delete)
    func updateNotes(content: String?) async throws {
        let me = try await AuthAPIService.shared.getCurrentUser()
        guard let groupId = me.groupId else { throw APIError.serverError(statusCode: 404, message: "가입한 그룹이 없습니다.") }
        guard let url = URL(string: APIConfig.baseURL + "/api/groups/\(groupId)/note") else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "authToken") { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let body = PatchNoteRequestBody(note: content)
        req.httpBody = try JSONEncoder().encode(body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode < 400 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: (resp as? HTTPURLResponse)?.statusCode ?? 500, message: msg)
        }
    }
    
    // MARK: - Log Management
    
    /// Create feeding log
    func createFeedingLog(checkerName: String, memo: String?) async throws -> ActivityLogResponse {
        let request = CreateActivityLogRequest(checkerName: checkerName, memo: memo)
        return try await client.request(endpoint: .createFeedingLog, body: request)
    }
    
    /// Create watering log
    func createWateringLog(checkerName: String, memo: String?) async throws -> ActivityLogResponse {
        let request = CreateActivityLogRequest(checkerName: checkerName, memo: memo)
        return try await client.request(endpoint: .createWateringLog, body: request)
    }
    
    /// Create poop log
    func createPoopLog(checkerName: String, memo: String?) async throws -> ActivityLogResponse {
        let request = CreateActivityLogRequest(checkerName: checkerName, memo: memo)
        return try await client.request(endpoint: .createPoopLog, body: request)
    }
}

// MARK: - Helper Extensions
extension PetLogAPIService {
    struct InviteCodeResponse: Codable { let statusCode: Int; let message: String; let data: [String:String] }

    /// Convert date to API format string
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.string(from: date)
    }

    /// Fetch invite code for a group (Test API spec)
    func getInviteCode(groupId: String) async throws -> String {
        let path = "/api/groups/\(groupId)/invite"
        guard let url = URL(string: APIConfig.baseURL + path) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500, message: msg)
        }
        let decoded = try JSONDecoder().decode(InviteCodeResponse.self, from: data)
        return decoded.data["joinCode"] ?? ""
    }
}
