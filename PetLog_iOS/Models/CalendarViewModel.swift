//
//  CalendarViewModel.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 11/15/25.
//

import Foundation
import Combine

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var monthlySchedules: [DaySchedules] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let apiService = ScheduleAPIService.shared
    private var currentMonth: Date = Date()
    private var currentGroupId: String?
    
    // Dictionary for fast lookup by date
    private var schedulesByDate: [String: [ScheduleItem]] = [:]
    
    // MARK: - Load Schedules
    
    func loadSchedules(for date: Date) async {
        // Get current groupId from UserDefaults
        let groupId = UserDefaults.standard.string(forKey: "groupId")
        
        // Check if we need to load:
        // 1. Different month, OR
        // 2. Different groupId (user switched groups)
        let calendar = Calendar.current
        let isDifferentMonth = !calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let isDifferentGroup = groupId != currentGroupId
        
        if isDifferentMonth || isDifferentGroup {
            print("🗓️ Reloading schedules - Month changed: \(isDifferentMonth), Group changed: \(isDifferentGroup)")
            currentMonth = date
            currentGroupId = groupId
            await fetchMonthlySchedules(for: date)
        }
    }
    
    private func fetchMonthlySchedules(for date: Date) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get group ID from UserDefaults
            guard let groupId = UserDefaults.standard.string(forKey: "groupId") else {
                print("❌ No group ID found, skipping schedule fetch")
                isLoading = false
                return
            }
            
            let yearMonth = ScheduleAPIService.formatYearMonth(date)
            print("📅 Fetching schedules for groupId: \(groupId), yearMonth: \(yearMonth)")
            let data = try await apiService.getMonthlySchedules(groupId: groupId, yearMonth: yearMonth)
            print("✅ Received \(data.monthlySchedules.count) day groups")
            for daySchedule in data.monthlySchedules {
                print("  - \(daySchedule.date): \(daySchedule.schedules.count) schedules")
            }
            
            monthlySchedules = data.monthlySchedules
            
            // Build lookup dictionary
            schedulesByDate = Dictionary(
                grouping: data.monthlySchedules.flatMap { daySchedule in
                    daySchedule.schedules.map { (date: daySchedule.date, schedule: $0) }
                },
                by: { $0.date }
            ).mapValues { $0.map { $0.schedule } }
            
            isLoading = false
            
        } catch APIError.serverError(let statusCode, let message) where statusCode == 404 {
            print("⚠️ No schedules found for this month")
            monthlySchedules = []
            schedulesByDate = [:]
            isLoading = false
            
        } catch let error as APIError {
            print("❌ API Error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
            
        } catch {
            print("❌ Unknown error: \(error.localizedDescription)")
            errorMessage = "일정을 불러오는데 실패했습니다."
            isLoading = false
        }
    }
    
    // MARK: - Cache Management
    
    /// Clear cached schedules (e.g., when group changes)
    func clearCache() {
        print("🗑️ Clearing calendar cache")
        monthlySchedules = []
        schedulesByDate = [:]
        currentMonth = Date()
        currentGroupId = nil
    }
    
    // MARK: - Helper Methods
    
    /// Get schedules for a specific date
    func schedulesForDate(_ date: Date) -> [ScheduleItem]? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"  // Match API format (e.g., "2025-12-03")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: date)
        return schedulesByDate[dateString]
    }
    
    /// Check if a date has schedules
    func hasSchedules(on date: Date) -> Bool {
        guard let schedules = schedulesForDate(date) else { return false }
        return !schedules.isEmpty
    }
    
    /// Get schedule count for a date
    func scheduleCount(for date: Date) -> Int {
        return schedulesForDate(date)?.count ?? 0
    }
}
