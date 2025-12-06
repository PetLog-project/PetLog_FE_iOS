import Foundation

// MARK: - Request/Response Models

// Group Management
struct CreateGroupRequest: Codable {
    let imageUrl: String?
    let name: String
    let age: String
    let weight: String
    let gender: String
    let feedingCycle: Int
    let lastFeedingTime: String  // ISO 8601: YYYY-MM-DDTHH:mm
    let wateringCycle: Int
    let lastWateringTime: String  // ISO 8601: YYYY-MM-DDTHH:mm
    let note: String?
}

struct JoinGroupRequest: Codable {
    let inviteCode: String
}

struct JoinGroupResponse: Codable {
    let code: Int
    let message: String
    let data: JoinGroupData
}

struct JoinGroupData: Codable {
    let groupId: String
}

struct LeaveGroupRequest: Codable {
    let groupId: String
}

// Pet Information
struct UpdatePetInfoRequest: Codable {
    let name: String?
    let age: String?
    let weight: String?
    let gender: String?
    let feedingCycle: Int?
    let wateringCycle: Int?
}

struct PetInfoResponse: Codable {
    let code: Int
    let message: String
    let data: PetInfoData
}

struct PetInfoData: Codable {
    let image: String?
    let name: String
    let age: String
    let weight: String
    let gender: String
    let feedingCycle: Int
    let wateringCycle: Int
    
    // Feeding log
    let lastFeedingTime: String
    let lastFeedingCheckerName: String
    let lastFeedingMemo: String?
    
    // Watering log
    let lastWateringTime: String
    let lastWateringCheckerName: String
    let lastWateringMemo: String?
    
    // Poop log
    let todayPoopCount: Int
    let lastPoopCheckerName: String
    let lastPoopMemo: String?
}

// Activity Logs
struct CreateActivityLogRequest: Codable {
    let checkerName: String
    let remindNotificationAt: String?
    let memo: String?
}

struct ActivityLogResponse: Codable {
    let code: Int
    let message: String
    let data: ActivityLogData?
}

struct ActivityLogData: Codable {
    let id: String
    let timestamp: String
}

// Notes
struct UpdateNoteRequest: Codable {
    let note: String?
    
    enum CodingKeys: String, CodingKey {
        case note
    }
}

struct NoteResponse: Codable {
    let code: Int
    let message: String
    let data: NoteData
}

struct NoteData: Codable {
    let note: String?
}

// Generic Response
struct SimpleResponse: Codable {
    let code: Int
    let message: String
}

// MARK: - PetLog API Service
class PetLogAPIService {
    static let shared = PetLogAPIService()
    private let client = APIClient.shared
    
    private init() {}
    
    // MARK: - Group Management
    
    /// Get my groups (명세서: GET /api/groups/my)
    func getMyGroups() async throws -> [String] {
        struct MyGroupsData: Decodable {
            let groupIds: [Int]
        }
        struct MyGroupsEnvelope: Decodable {
            let code: Int
            let message: String
            let data: MyGroupsData
        }
        
        let response: MyGroupsEnvelope = try await client.request(endpoint: .getMyGroups)
        // Convert Int array to String array
        return response.data.groupIds.map { String($0) }
    }
    
    /// Get my group's pet information
    func getMyGroup() async throws -> PetDashboardResponse {
        // 1) Get groupId from UserDefaults
        guard let groupId = UserDefaults.standard.string(forKey: "groupId") else {
            throw APIError.serverError(statusCode: 404, message: "가입한 그룹이 없습니다.")
        }
        // 2) Fetch pet info
        struct Envelope<T: Decodable>: Decodable { let code:Int; let message:String; let data:T }
        struct PetProfileByGroup: Decodable { let imageUrl:String?; let name:String; let age:String; let weight:String; let gender:String }
        struct FeedingDTO: Decodable { let feedingCycle:Int; let lastFeedingTime:String; let lastCheckerName:String; let lastMemo:String? }
        struct WateringDTO: Decodable { let wateringCycle:Int; let lastWateringTime:String; let lastCheckerName:String; let lastMemo:String? }
        struct PoopDTO: Decodable { let todayPoopCount:Int; let lastCheckerName:String; let lastMemo:String? }
        struct PetInfoByGroupDTO: Decodable {
            let profile: PetProfileByGroup
            let feedingInfo: FeedingDTO
            let wateringInfo: WateringDTO
            let poopInfo: PoopDTO
            
            enum CodingKeys: String, CodingKey {
                case profile
                case feedingInfo = "feedingInfo"
                case wateringInfo = "wateringInfo"
                case poopInfo = "poopInfo"
            }
        }

        let path = "/api/groups/\(groupId)/pet"
        guard let url = URL(string: APIConfig.baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Use accessToken (stored by AuthAPIService during login)
        let accessToken = UserDefaults.standard.string(forKey: "accessToken")
        let authToken = UserDefaults.standard.string(forKey: "authToken")
        let token = accessToken ?? authToken
        
        print("🔴 [getMyGroup] Token check:")
        print("   accessToken: \(accessToken != nil ? "✅ Present (\(accessToken!.prefix(20))...)" : "❌ Missing")")
        print("   authToken: \(authToken != nil ? "✅ Present (\(authToken!.prefix(20))...)" : "❌ Missing")")
        print("   Using token: \(token != nil ? "✅ Present" : "❌ Missing")")
        
        if let token = token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 400 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            print("🔴 [getMyGroup] HTTP Error: statusCode=\(code), message=\(msg)")
            
            // If 403, try refreshing token and retrying once
            if code == 403 {
                print("🔄 [getMyGroup] Got 403, attempting token refresh...")
                do {
                    let newAccessToken = try await AuthAPIService.shared.refreshAccessToken()
                    print("✅ [getMyGroup] Token refreshed successfully")
                    
                    // Retry with new token
                    var retryReq = URLRequest(url: url)
                    retryReq.httpMethod = "GET"
                    retryReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    retryReq.setValue("Bearer \(newAccessToken)", forHTTPHeaderField: "Authorization")
                    
                    let (retryData, retryResponse) = try await URLSession.shared.data(for: retryReq)
                    guard let retryHttpResponse = retryResponse as? HTTPURLResponse, retryHttpResponse.statusCode < 400 else {
                        let retryMsg = String(data: retryData, encoding: .utf8) ?? "Unknown error"
                        throw APIError.serverError(statusCode: (retryResponse as? HTTPURLResponse)?.statusCode ?? 500, message: retryMsg)
                    }
                    
                    print("✅ [getMyGroup] Retry successful with new token")
                    
                    // Debug print formatted JSON
                    if let jsonStr = String(data: retryData, encoding: .utf8) {
                        print("✅ [getMyGroup] Raw response (formatted):")
                        if let jsonData = jsonStr.data(using: .utf8),
                           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
                           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                           let prettyStr = String(data: prettyData, encoding: .utf8) {
                            print(prettyStr)
                        } else {
                            print(jsonStr)
                        }
                    }
                    
                    // Decode and map
                    let retryDecoded = try JSONDecoder().decode(Envelope<PetInfoByGroupDTO>.self, from: retryData)
                    
                    // 3) Fetch invite code (joinCode)
                    let joinCode = try await getInviteCode(groupId: groupId)
                    
                    // 4) Map to PetDashboardResponse
                    func parseTime(_ s: String) -> Date {
                        // Try parsing with fractional seconds first
                        let df = DateFormatter()
                        df.locale = Locale(identifier: "en_US_POSIX")
                        df.timeZone = TimeZone(identifier: "Asia/Seoul") // Backend sends KST
                        
                        // Format: 2025-12-04T17:45:12.66037 (with fractional seconds)
                        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                        if let date = df.date(from: s) { return date }
                        
                        // Format: 2025-12-03T00:24:00 (without fractional seconds)
                        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                        if let date = df.date(from: s) { return date }
                        
                        return Date()
                    }
                    let prof = retryDecoded.data.profile
                    let homeProfile = Profile(imageUrl: prof.imageUrl ?? "", name: prof.name, age: prof.age, weight: prof.weight, gender: Gender(rawValue: prof.gender) ?? .female)
                    let feed = retryDecoded.data.feedingInfo
                    let homeFeeding = Feeding(feedingCycle: feed.feedingCycle, lastFeedingTime: parseTime(feed.lastFeedingTime), lastCheckerName: feed.lastCheckerName, lastMemo: feed.lastMemo ?? "")
                    let water = retryDecoded.data.wateringInfo
                    let homeWater = Watering(wateringCycle: water.wateringCycle, lastWateringTime: parseTime(water.lastWateringTime), lastCheckerName: water.lastCheckerName, lastMemo: water.lastMemo ?? "")
                    let poop = retryDecoded.data.poopInfo
                    let homePoop = Poop(todayPoopCount: poop.todayPoopCount, lastCheckerName: poop.lastCheckerName, lastMemo: poop.lastMemo ?? "")
                    let homeData = PetDashboardData(profile: homeProfile, feeding: homeFeeding, watering: homeWater, poop: homePoop, joinCode: joinCode)
                    return PetDashboardResponse(code: retryDecoded.code, message: retryDecoded.message, data: homeData)
                } catch {
                    print("❌ [getMyGroup] Token refresh failed: \(error)")
                    throw APIError.serverError(statusCode: code, message: msg)
                }
            }
            
            throw APIError.serverError(statusCode: code, message: msg)
        }
        
        // Debug: Print raw response (formatted)
        if let jsonStr = String(data: data, encoding: .utf8) {
            print("✅ [getMyGroup] Raw response (formatted):")
            if let jsonData = jsonStr.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyStr = String(data: prettyData, encoding: .utf8) {
                print(prettyStr)
            } else {
                print(jsonStr)
            }
        }
        
        let decoded = try JSONDecoder().decode(Envelope<PetInfoByGroupDTO>.self, from: data)

        // 3) Fetch invite code (joinCode)
        let joinCode = try await getInviteCode(groupId: groupId)

        // 4) Map to PetDashboardResponse
        func parseTime(_ s: String) -> Date {
            // Try parsing with fractional seconds first
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(identifier: "Asia/Seoul") // Backend sends KST
            
            // Format: 2025-12-04T17:45:12.66037 (with fractional seconds)
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = df.date(from: s) { return date }
            
            // Format: 2025-12-03T00:24:00 (without fractional seconds)
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = df.date(from: s) { return date }
            
            return Date()
        }
        let prof = decoded.data.profile
        let homeProfile = Profile(imageUrl: prof.imageUrl ?? "", name: prof.name, age: prof.age, weight: prof.weight, gender: Gender(rawValue: prof.gender) ?? .female)
        let feed = decoded.data.feedingInfo
        let homeFeeding = Feeding(feedingCycle: feed.feedingCycle, lastFeedingTime: parseTime(feed.lastFeedingTime), lastCheckerName: feed.lastCheckerName, lastMemo: feed.lastMemo ?? "")
        let water = decoded.data.wateringInfo
        let homeWater = Watering(wateringCycle: water.wateringCycle, lastWateringTime: parseTime(water.lastWateringTime), lastCheckerName: water.lastCheckerName, lastMemo: water.lastMemo ?? "")
        let poop = decoded.data.poopInfo
        let homePoop = Poop(todayPoopCount: poop.todayPoopCount, lastCheckerName: poop.lastCheckerName, lastMemo: poop.lastMemo ?? "")
        let homeData = PetDashboardData(profile: homeProfile, feeding: homeFeeding, watering: homeWater, poop: homePoop, joinCode: joinCode)
        return PetDashboardResponse(code: decoded.code, message: decoded.message, data: homeData)
    }
    
    /// Create a new group (명세서: POST /api/groups)
    func createGroup(request: CreateGroupRequest) async throws -> SimpleResponse {
        return try await client.request(endpoint: .createGroup, body: request)
    }
    
    /// Join existing group with code (명세서: POST /api/groups/join)
    func joinGroup(inviteCode: String) async throws -> JoinGroupData {
        let request = JoinGroupRequest(inviteCode: inviteCode)
        let response: JoinGroupResponse = try await client.request(endpoint: .joinGroup, body: request)
        return response.data
    }
    
    /// Leave group (명세서: DELETE /api/groups/{groupId}/leave)
    func leaveGroup(groupId: String) async throws {
        try await client.requestWithoutResponse(endpoint: .leaveGroup(groupId: groupId))
    }
    
    /// Get invite code for group (명세서: GET /api/groups/{groupId}/invite)
    func getInviteCode(groupId: String) async throws -> String {
        struct InviteCodeData: Decodable {
            let joinCode: String
        }
        struct InviteCodeEnvelope: Decodable {
            let code: Int
            let message: String
            let data: InviteCodeData
        }
        
        let response: InviteCodeEnvelope = try await client.request(endpoint: .getInviteCode(groupId: groupId))
        return response.data.joinCode
    }
    
    /// Get pet info (명세서: GET /api/groups/{groupId}/pet)
    func getPetInfo(groupId: String) async throws -> PetInfoData {
        let response: PetInfoResponse = try await client.request(endpoint: .getPetInfo(groupId: groupId))
        return response.data
    }
    
    /// Update pet info (명세서: PATCH /api/groups/{groupId}/pet)
    func updatePetInfo(groupId: String, request: UpdatePetInfoRequest) async throws -> SimpleResponse {
        return try await client.request(endpoint: .updatePetInfo(groupId: groupId), body: request)
    }
    
    // MARK: - Notes Management
    
    /// Get note for group (명세서: GET /api/groups/{groupId}/note)
    func getNote(groupId: String) async throws -> String? {
        print("📤 [getNote] Calling API for groupId: \(groupId)")
        let response: NoteResponse = try await client.request(endpoint: .getNote(groupId: groupId))
        print("✅ [getNote] Response received:")
        print("   code: \(response.code)")
        print("   message: \(response.message)")
        print("   note: \(response.data.note == nil ? "nil" : "'\(response.data.note!)'" )")
        return response.data.note
    }
    
    /// Update note for group (명세서: PUT /api/groups/{groupId}/note)
    func updateNote(groupId: String, content: String?) async throws {
        print("📤 [updateNote] Preparing request for groupId: \(groupId)")
        let request = UpdateNoteRequest(note: content)
        print("   note: \(content == nil ? "nil" : "'\(content!)'" )")
        
        // Debug: Encode request to see actual JSON
        if let encoded = try? JSONEncoder().encode(request),
           let jsonStr = String(data: encoded, encoding: .utf8) {
            print("   Request JSON: \(jsonStr)")
        }
        
        let _: SimpleResponse = try await client.request(endpoint: .updateNote(groupId: groupId), body: request)
        print("✅ [updateNote] Request sent successfully")
    }
    
    /// Update pet profile with image URL (명세서: PATCH /api/groups/{groupId}/pet)
    func updateProfile(name: String, age: String, weight: String, gender: Gender, imageUrl: String) async throws {
        guard let groupId = UserDefaults.standard.string(forKey: "groupId") else {
            throw APIError.serverError(statusCode: 404, message: "가입한 그룹이 없습니다.")
        }
        
        struct UpdateProfileRequest: Codable {
            let imageUrl: String
            let name: String
            let age: String
            let weight: String
            let gender: String
        }
        
        let request = UpdateProfileRequest(
            imageUrl: imageUrl,
            name: name,
            age: age,
            weight: weight.contains("kg") || weight.contains("g") ? weight : "\(weight)kg",
            gender: gender.rawValue
        )
        
        print("📸 [updateProfile] Updating pet profile")
        print("   groupId: \(groupId)")
        print("   imageUrl: \(imageUrl)")
        print("   name: \(name)")
        print("   age: \(age)")
        print("   weight: \(weight)")
        print("   gender: \(gender.rawValue)")
        
        // Use direct URLRequest to bypass client request mechanism
        // This prevents duplicate PATCH requests from binding changes
        guard let url = URL(string: APIConfig.baseURL + "/api/groups/\(groupId)/pet") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 400 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw APIError.serverError(statusCode: code, message: msg)
        }
        
        print("✅ [updateProfile] Profile updated successfully")
    }
    
    // MARK: - Activity Logs
    
    /// Create feeding log (명세서: POST /api/groups/{groupId}/pet/feeding)
    func createFeedingLog(groupId: String, checkerName: String, remindNotificationAt: String? = nil, memo: String? = nil) async throws -> ActivityLogData? {
        let request = CreateActivityLogRequest(checkerName: checkerName, remindNotificationAt: remindNotificationAt, memo: memo)
        let response: ActivityLogResponse = try await client.request(endpoint: .createFeedingLog(groupId: groupId), body: request)
        return response.data
    }
    
    /// Create watering log (명세서: POST /api/groups/{groupId}/pet/watering)
    func createWateringLog(groupId: String, checkerName: String, remindNotificationAt: String? = nil, memo: String? = nil) async throws -> ActivityLogData? {
        let request = CreateActivityLogRequest(checkerName: checkerName, remindNotificationAt: remindNotificationAt, memo: memo)
        let response: ActivityLogResponse = try await client.request(endpoint: .createWateringLog(groupId: groupId), body: request)
        return response.data
    }
    
    /// Create poop log (명세서: POST /api/groups/{groupId}/pet/poop)
    func createPoopLog(groupId: String, checkerName: String, remindNotificationAt: String? = nil, memo: String? = nil) async throws -> ActivityLogData? {
        let request = CreateActivityLogRequest(checkerName: checkerName, remindNotificationAt: remindNotificationAt, memo: memo)
        let response: ActivityLogResponse = try await client.request(endpoint: .createPoopLog(groupId: groupId), body: request)
        return response.data
    }
    
    // MARK: - Notification
    
    /// Save push token to backend (명세서: POST /api/notification/token)
    func savePushToken(token: String) async throws {
        struct SaveTokenRequest: Encodable {
            let token: String
        }
        
        let request = SaveTokenRequest(token: token)
        let _: SimpleResponse = try await client.request(endpoint: .savePushToken, body: request)
    }
    
    /// Delete push token from backend (명세서: DELETE /api/notification/token)
    func deletePushToken() async throws {
        try await client.requestWithoutResponse(endpoint: .deletePushToken)
    }
    
    /// Set notification preferences (명세서: PUT /api/notification)
    func setNotificationPreference(feedingReminder: Bool, wateringReminder: Bool, poopReminder: Bool) async throws {
        struct NotificationPreferenceRequest: Encodable {
            let feedingReminder: Bool
            let wateringReminder: Bool
            let poopReminder: Bool
        }
        
        let request = NotificationPreferenceRequest(
            feedingReminder: feedingReminder,
            wateringReminder: wateringReminder,
            poopReminder: poopReminder
        )
        let _: SimpleResponse = try await client.request(endpoint: .setNotificationPreference, body: request)
    }
    
    /// Get notification preferences (명세서: GET /api/notification)
    func getNotificationPreference() async throws -> NotificationPreferenceData {
        struct NotificationPreferenceResponse: Decodable {
            let code: Int
            let message: String
            let data: NotificationPreferenceData
        }
        
        let response: NotificationPreferenceResponse = try await client.request(endpoint: .getNotificationPreference)
        return response.data
    }
    
    // MARK: - Helper Methods
    
    /// Convert date to API format string (YYYY-MM-DDTHH:mm)
    static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Notification Models
struct NotificationPreferenceData: Decodable {
    let feedingReminder: Bool
    let wateringReminder: Bool
    let poopReminder: Bool
}
