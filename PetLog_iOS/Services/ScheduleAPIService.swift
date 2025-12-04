import Foundation

// MARK: - Schedule API Service
// 주의: 스케줄 관련 모델은 Models/ScheduleModels.swift에 정의되어 있습니다. 이 파일에서는 중복 정의를 제거했습니다.
class ScheduleAPIService {
    static let shared = ScheduleAPIService()
    private let client = APIClient.shared
    
    private init() {}
    
    // MARK: - Get Monthly Schedules
    /// Fetch schedules for a specific month (명세서: GET /api/groups/{groupId}/schedule?date=YYYY-MM)
    func getMonthlySchedules(groupId: String, yearMonth: String) async throws -> MonthlySchedulesData {
        // Note: APIClient doesn't support query parameters yet, so we use direct URLRequest
        guard let url = URL(string: APIConfig.baseURL + "/api/groups/\(groupId)/schedule?date=\(yearMonth)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode >= 400 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Debug: Print raw response
        if let jsonStr = String(data: data, encoding: .utf8) {
            print("📅 [getMonthlySchedules] Raw response: \(jsonStr)")
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MonthlySchedulesResponse.self, from: data)
        return decoded.data
    }
    
    // MARK: - Create Schedule
    /// Create a new schedule (명세서: POST /api/groups/{groupId}/schedule)
    func createSchedule(groupId: String, request: CreateScheduleRequest) async throws -> String {
        guard let url = URL(string: APIConfig.baseURL + "/api/groups/\(groupId)/schedule") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode >= 400 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📤 Schedule creation response: \(responseString)")
        }
        
        struct ScheduleResponse: Decodable {
            let code: Int
            let message: String
            let data: ScheduleData?
        }
        
        struct ScheduleData: Decodable {
            let scheduleId: String?
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ScheduleResponse.self, from: data)
        
        // Backend returns 201 with message but no scheduleId in data
        // Generate a temporary ID or return empty string to indicate success
        if let scheduleId = decoded.data?.scheduleId {
            return scheduleId
        } else {
            // Return a placeholder - the important thing is the 201 response indicates success
            print("⚠️ [createSchedule] No scheduleId in response, but creation succeeded (201)")
            return "temp-\(UUID().uuidString)"
        }
    }
    
    // MARK: - Update Schedule
    /// Update an existing schedule (명세서: PATCH /api/groups/{groupId}/schedule/{scheduleId})
    /// Note: This endpoint is not defined in the current APIEndpoint enum
    func updateSchedule(groupId: String, scheduleId: String, request: PatchScheduleRequest) async throws {
        guard let url = URL(string: APIConfig.baseURL + "/api/groups/\(groupId)/schedule/\(scheduleId)") else {
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode >= 400 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
    
    // MARK: - Delete Schedule
    /// Delete a schedule (명세서: DELETE /api/groups/{groupId}/schedule/{scheduleId})
    /// Note: This endpoint is not defined in the current APIEndpoint enum
    func deleteSchedule(groupId: String, scheduleId: String) async throws {
        guard let url = URL(string: APIConfig.baseURL + "/api/groups/\(groupId)/schedule/\(scheduleId)") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode >= 400 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Format a date to YYYY-MM for API queries
    static func formatYearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    /// Format a date for schedule (YYYY-MM-DDTHH:mm:ss)
    /// Note: Always include time even for all-day events (backend expects LocalDateTime)
    static func formatScheduleDateTime(_ date: Date, isAllDay: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Always use full datetime format for all-day (backend parses as LocalDateTime)
        formatter.dateFormat = isAllDay ? "yyyy-MM-dd'T'00:00:00" : "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.string(from: date)
    }
}

