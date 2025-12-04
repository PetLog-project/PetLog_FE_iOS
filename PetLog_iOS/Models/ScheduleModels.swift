//
//  ScheduleModels.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 11/15/25.
//

import Foundation

// MARK: - Schedule Tag
enum ScheduleTag: String, Codable {
    case YELLOW
    case GREEN
    case BLUE
}

// MARK: - Schedule Item
struct ScheduleItem: Codable, Identifiable {
    let scheduleId: Int
    let title: String
    let isAllDay: Bool
    let startAt: String  // ISO8601 format
    let endAt: String
    let tag: ScheduleTag
    let remindNotificationAt: String?
    let memo: String?
    
    var id: Int { scheduleId }
    
    // Computed property for parsed date
    var startDate: Date? {
        parseScheduleDate(startAt)
    }
    
    var endDate: Date? {
        parseScheduleDate(endAt)
    }
    
    private func parseScheduleDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        // Try full date-time format first
        if let date = formatter.date(from: dateString + ":00Z") {
            return date
        }
        
        // Try date-only format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.date(from: dateString)
    }
}

// MARK: - Day Schedules
struct DaySchedules: Codable {
    let date: String  // YYYY.MM.DD (from API)
    let schedules: [ScheduleItem]
    
    // Computed property for parsed date
    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"  // API format: "2025-12-03"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: date)
    }
}

// MARK: - Monthly Schedules Data
struct MonthlySchedulesData: Codable {
    let monthlySchedules: [DaySchedules]
}

// MARK: - API Response
struct MonthlySchedulesResponse: Codable {
    let code: Int
    let message: String
    let data: MonthlySchedulesData
}

// MARK: - Create Schedule Request
struct CreateScheduleRequest: Codable {
    let title: String
    let isAllDay: Bool
    let startTime: String
    let endTime: String
    let tag: ScheduleTag
    let remindNotificationAt: String?
    let memo: String?
}

// MARK: - Patch Schedule Request
struct PatchScheduleRequest: Codable {
    let title: String?
    let isAllDay: Bool?
    let startAt: String?
    let endAt: String?
    let tag: ScheduleTag?
    let remindNotificationAt: String?
    let memo: String?
    
    enum CodingKeys: String, CodingKey {
        case title, isAllDay, startAt, endAt, tag, remindNotificationAt, memo
    }
}
