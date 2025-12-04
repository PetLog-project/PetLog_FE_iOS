//
//  CalendarView.swift
//  PetLog_iOS
//
//  Created by Dongha Ryu on 10/31/25.
//  Updated by DonghaRyu on 11/15/25 - Figma design implementation
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate: Date = Date()
    @State private var hasSelectedDate = false
    @State private var showAddSchedule = false
    @State private var selectedSchedule: ScheduleItem?
    @State private var showScheduleDetail = false
    @State private var showDateDetail = false
    @State private var contentOpacity: Double = 0
    
    private let calendar = Calendar.current
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
    @State private var currentGroupId: String?
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Month navigation header
                monthNavigationHeader
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.md)
                
                // Weekday headers
                weekdayHeader
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.sm)
                
                // Calendar grid
                ScrollView {
                    VStack(spacing: 0) {
                        calendarGrid
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Spacer for bottom padding
                        Spacer()
                            .frame(height: Theme.Spacing.xl)
                    }
                }
            }
            .opacity(contentOpacity)
            
            // Add schedule button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showAddSchedule = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Theme.Colors.mainYellow)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .opacity(contentOpacity)
                    .padding(.trailing, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
        }
        .onAppear {
            let groupId = UserDefaults.standard.string(forKey: "groupId")
            let groupChanged = groupId != currentGroupId
            
            print("📅 CalendarView appeared - Current date: \(selectedDate)")
            print("📅 Current group: \(currentGroupId ?? "nil"), New group: \(groupId ?? "nil"), Changed: \(groupChanged)")
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            print("📅 Fetching schedules for: \(formatter.string(from: selectedDate))")
            
            // Force reload if group changed
            if groupChanged {
                viewModel.clearCache()
                currentGroupId = groupId
            }
            
            Task {
                await viewModel.loadSchedules(for: selectedDate)
                print("📅 Schedule fetch completed. Total day groups: \(viewModel.monthlySchedules.count)")
            }
            
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1.0
            }
        }
        .onDisappear {
            contentOpacity = 0
        }
        .sheet(isPresented: $showAddSchedule) {
            AddScheduleView(currentDate: selectedDate) {
                // Clear cache and force reload after saving
                viewModel.clearCache()
                Task {
                    await viewModel.loadSchedules(for: selectedDate)
                }
            }
        }
        .sheet(isPresented: $showScheduleDetail) {
            if let schedule = selectedSchedule {
                ScheduleDetailView(schedule: schedule) {
                    Task {
                        await viewModel.loadSchedules(for: selectedDate)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showDateDetail) {
            DateDetailView(
                date: selectedDate,
                schedules: viewModel.schedulesForDate(selectedDate) ?? [],
                onScheduleTap: { schedule in
                    showDateDetail = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedSchedule = schedule
                        showScheduleDetail = true
                    }
                },
                onAddSchedule: {
                    showDateDetail = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showAddSchedule = true
                    }
                },
                onDismiss: {
                    showDateDetail = false
                }
            )
            .background(ClearBackgroundView())
        }
    }
    
    // MARK: - Month Navigation Header
    private var monthNavigationHeader: some View {
        HStack(alignment: .top) {
            // Large month display
            Text(monthString)
                .font(Theme.Typography.headingXXL)
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            // Date picker section
            VStack(alignment: .trailing, spacing: 4) {
                Text("날짜 변경")
                    .font(Theme.Typography.headingM)
                    .foregroundColor(Theme.Colors.text)
                
                HStack(spacing: 20) {
                // Year picker
                    Menu {
                        ForEach(2020...2050, id: \.self) { year in
                            Button(formatYearForPicker(year)) {
                                updateYear(to: year)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(yearString)
                                .font(Theme.Typography.boldL)
                                .foregroundColor(Theme.Colors.text)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.Colors.text)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#F5F7F8"))
                        .cornerRadius(8)
                    }
                    
                    // Month picker
                    Menu {
                        ForEach(1...12, id: \.self) { month in
                            Button("\(month)월") {
                                updateMonth(to: month)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(monthNumberString)
                                .font(Theme.Typography.boldL)
                                .foregroundColor(Theme.Colors.text)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.Colors.text)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#F5F7F8"))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdaySymbols[index])
                        .font(Theme.Typography.boldM)
                        .foregroundColor(index == 0 ? Color(hex: "#FF6161") : (index == 6 ? Color(hex: "#5C9BFF") : Theme.Colors.text))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)
            
            // Yellow underline
            Rectangle()
                .fill(Theme.Colors.mainYellow)
                .frame(height: 2)
        }
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        
        return LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    CalendarDayCell(
                        date: date,
                        isSelected: hasSelectedDate && calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        schedules: viewModel.schedulesForDate(date) ?? [],
                        onTap: { 
                            selectedDate = date
                            hasSelectedDate = true
                            showDateDetail = true
                        }
                    )
                } else {
                    Color.clear
                        .frame(height: 60)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: selectedDate)
    }
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: selectedDate)
    }
    
    private var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: selectedDate)
    }
    
    private var monthNumberString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: selectedDate)
    }
    
    private func updateYear(to year: Int) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.year = year
        if let newDate = calendar.date(from: components) {
            print("📅 Year changed to: \(year)")
            withAnimation {
                selectedDate = newDate
            }
            Task {
                await viewModel.loadSchedules(for: newDate)
                print("📅 Schedule fetch completed after year change")
            }
        }
    }
    
    private func updateMonth(to month: Int) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.month = month
        if let newDate = calendar.date(from: components) {
            print("📅 Month changed to: \(month)")
            withAnimation {
                selectedDate = newDate
            }
            Task {
                await viewModel.loadSchedules(for: newDate)
                print("📅 Schedule fetch completed after month change")
            }
        }
    }
    
    private func dateHeaderString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
            Task {
                await viewModel.loadSchedules(for: newDate)
            }
        }
    }
    
    private func formatYearForPicker(_ year: Int) -> String {
        return "\(year)년"
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingEmptyDays = firstWeekday - 1
        
        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        
        return days
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let schedules: [ScheduleItem]
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Text("\(calendar.component(.day, from: date))")
                    .font(Theme.Typography.boldM)
                    .foregroundColor(textColor)
                    .padding(.bottom, 0.5)
                    .padding(.top, 1)
                
                // Schedule indicator dots (max 3)
                HStack(spacing: 2) {
                    ForEach(schedules.prefix(3)) { schedule in
                        Circle()
                            .fill(tagColor(for: schedule.tag))
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(height: 12)
                
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
            .padding(.horizontal, 2)
            .frame(width: 42, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? Theme.Colors.mainYellow : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var textColor: Color {
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 { // Sunday
            return Color(hex: "#FF6161")
        } else if weekday == 7 { // Saturday
            return Color(hex: "#5C9BFF")
        }
        return Theme.Colors.text
    }
    
    private func tagColor(for tag: ScheduleTag) -> Color {
        switch tag {
        case .YELLOW: return Theme.Colors.mainYellow
        case .GREEN: return Color(hex: "#81C26C")
        case .BLUE: return Color(hex: "#5C9BFF")
        }
    }
}

// MARK: - Schedule Card
struct ScheduleCard: View {
    let schedule: ScheduleItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Tag color indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(tagColor)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(schedule.title)
                        .font(Theme.Typography.boldM)
                        .foregroundColor(Theme.Colors.text)
                    
                    Text(timeString)
                        .font(Theme.Typography.bodyXS)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    if let memo = schedule.memo, !memo.isEmpty {
                        Text(memo)
                            .font(Theme.Typography.bodyXS)
                            .foregroundColor(Theme.Colors.tertiaryText)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.Colors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var tagColor: Color {
        switch schedule.tag {
        case .YELLOW: return Theme.Colors.mainYellow
        case .GREEN: return .green
        case .BLUE: return Theme.Colors.blue
        }
    }
    
    private var timeString: String {
        if schedule.isAllDay {
            return "하루종일"
        } else {
            let start = schedule.startAt.suffix(5) // HH:mm
            let end = schedule.endAt.suffix(5)
            return "\(start) - \(end)"
        }
    }
}

// MARK: - Schedule Detail View
struct ScheduleDetailView: View {
    let schedule: ScheduleItem
    let onUpdate: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var isDeleting = false
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                    }
                    
                    Spacer()
                    
                    Text("일정 상세")
                        .font(Theme.Typography.headingL)
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 20, height: 20)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.lg)
                .background(Theme.Colors.white)
                
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Title with tag color dot
                        HStack(spacing: 12) {
                            Text(schedule.title)
                                .font(Theme.Typography.headingL)
                                .foregroundColor(Theme.Colors.text)
                            
                            Spacer()
                            
                            Circle()
                                .fill(tagColor)
                                .frame(width: 16, height: 16)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.md)
                        
                        Divider()
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Date and Time info
                        if schedule.isAllDay {
                            // All-day event
                            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                HStack(spacing: 20) {
                                    Text(formatDate(schedule.startAt))
                                        .font(Theme.Typography.bodyM)
                                        .foregroundColor(Theme.Colors.text)
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.Colors.text)
                                    
                                    Text(formatDate(schedule.endAt))
                                        .font(Theme.Typography.bodyM)
                                        .foregroundColor(Theme.Colors.text)
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.md)
                        } else {
                            // Timed event - two columns layout
                            HStack(alignment: .top, spacing: Theme.Spacing.xl) {
                                // Start column
                                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                    Text(formatDate(schedule.startAt))
                                        .font(Theme.Typography.bodyM)
                                        .foregroundColor(Theme.Colors.text)
                                    Text(formatTime(schedule.startAt))
                                        .font(Theme.Typography.bodyM)
                                        .foregroundColor(Theme.Colors.text)
                                }
                                
                                // Arrow
                                VStack {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.Colors.text)
                                    Spacer()
                                }
                                .frame(height: 50)
                                
                                // End column
                                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                    Text(formatDate(schedule.endAt))
                                        .font(Theme.Typography.bodyM)
                                        .foregroundColor(Theme.Colors.text)
                                    Text(formatTime(schedule.endAt))
                                        .font(Theme.Typography.bodyM)
                                        .foregroundColor(Theme.Colors.text)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.md)
                        }
                        
                        Divider()
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Reminder info
                        if let remindTime = schedule.remindNotificationAt {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "bell")
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.Colors.text)
                                
                                Text("리마인드")
                                    .font(Theme.Typography.bodyM)
                                    .foregroundColor(Theme.Colors.text)
                                
                                Text(formatReminderTime(remindTime))
                                    .font(Theme.Typography.bodyM)
                                    .foregroundColor(Theme.Colors.text)
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.md)
                            
                            Divider()
                                .padding(.horizontal, Theme.Spacing.lg)
                        }
                        
                        // Memo
                        if let memo = schedule.memo, !memo.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("참고 사항")
                                    .font(Theme.Typography.bodyM)
                                    .foregroundColor(Theme.Colors.text)
                                
                                Text(memo)
                                    .font(Theme.Typography.bodyM)
                                    .foregroundColor(Theme.Colors.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(Theme.Spacing.md)
                                    .background(Color(hex: "#F5F7F8"))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.md)
                            
                            Divider()
                                .padding(.horizontal, Theme.Spacing.lg)
                        }
                        
                        Spacer()
                            .frame(height: Theme.Spacing.lg)
                    }
                }
                
                Spacer()
            }
        }
        
                // Action buttons
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 0) {
                        Button(action: { showEditSheet = true }) {
                            HStack(spacing: 4) {
                                Image("icon_park_outline_write")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                Text("편집")
                                    .font(Theme.Typography.bodyM)
                            }
                            .foregroundColor(Theme.Colors.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        Button(action: { showDeleteAlert = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                Text("삭제")
                                    .font(Theme.Typography.bodyM)
                            }
                            .foregroundColor(Theme.Colors.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                    }
                }
                .background(Theme.Colors.white)
        .alert("일정 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                Task { await deleteSchedule() }
            }
        } message: {
            Text("이 일정을 삭제하시겠습니까?")
        }
        .sheet(isPresented: $showEditSheet) {
            EditScheduleView(schedule: schedule) {
                Task {
                    await dismiss()
                    onUpdate()
                }
            }
        }
    }
    
    private var tagColor: Color {
        switch schedule.tag {
        case .YELLOW: return Theme.Colors.mainYellow
        case .GREEN: return .green
        case .BLUE: return Theme.Colors.blue
        }
    }
    
    private var tagName: String {
        switch schedule.tag {
        case .YELLOW: return "노랑"
        case .GREEN: return "초록"
        case .BLUE: return "파랑"
        }
    }
    
    // Format date as "yyyy년 M월 d일 (E)" - handles both "yyyy-MM-dd" and "yyyy-MM-dd'T'HH:mm:ss" formats
    private func formatDate(_ dateString: String) -> String {
        // Try ISO format with seconds (yyyy-MM-dd'T'HH:mm:ss)
        let isoFormatterWithSeconds = DateFormatter()
        isoFormatterWithSeconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        isoFormatterWithSeconds.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = isoFormatterWithSeconds.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy년 M월 d일 (E)"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        // Try ISO format without seconds (yyyy-MM-dd'T'HH:mm)
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = isoFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy년 M월 d일 (E)"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        // Try date-only format (yyyy-MM-dd)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = dateFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy년 M월 d일 (E)"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        return dateString
    }
    
    // Format time as "오전 12:00" - from "yyyy-MM-dd'T'HH:mm:ss" format
    private func formatTime(_ dateTimeString: String) -> String {
        // Try with seconds first
        let formatterWithSeconds = DateFormatter()
        formatterWithSeconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatterWithSeconds.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = formatterWithSeconds.date(from: dateTimeString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "a h:mm"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        // Try without seconds
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let date = formatter.date(from: dateTimeString) else {
            return dateTimeString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "a h:mm"
        outputFormatter.locale = Locale(identifier: "ko_KR")
        return outputFormatter.string(from: date)
    }
    
    // Format reminder time - from "yyyy-MM-dd'T'HH:mm:ss" format
    private func formatReminderTime(_ dateTimeString: String) -> String {
        // Try with seconds first
        let formatterWithSeconds = DateFormatter()
        formatterWithSeconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatterWithSeconds.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = formatterWithSeconds.date(from: dateTimeString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy년 M월 d일 a h시 m분"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        // Try without seconds
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let date = formatter.date(from: dateTimeString) else {
            return dateTimeString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy년 M월 d일 a h시 m분"
        outputFormatter.locale = Locale(identifier: "ko_KR")
        return outputFormatter.string(from: date)
    }
    
    private func deleteSchedule() async {
        guard let groupId = UserDefaults.standard.string(forKey: "groupId") else { return }
        isDeleting = true
        
        do {
            try await ScheduleAPIService.shared.deleteSchedule(
                groupId: groupId,
                scheduleId: String(schedule.scheduleId)
            )
            dismiss()
            onUpdate()
        } catch {
            print("Failed to delete schedule: \(error)")
            isDeleting = false
        }
    }
}

// AddScheduleView is now in AddScheduleView.swift
// EditScheduleView is now in EditScheduleView.swift
// TagColorPicker is now in Components/TagColorPicker.swift

// MARK: - Tag Button Component
struct TagButton: View {
    let tag: ScheduleTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                Circle()
                    .fill(tagColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Theme.Colors.cardBorder : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                    )
                
                Text(tagName)
                    .font(Theme.Typography.bodyXS)
                    .foregroundColor(isSelected ? Theme.Colors.text : Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
            .background(isSelected ? Theme.Colors.mainYellow.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var tagColor: Color {
        switch tag {
        case .YELLOW: return Theme.Colors.mainYellow
        case .GREEN: return .green
        case .BLUE: return Theme.Colors.blue
        }
    }
    
    private var tagName: String {
        switch tag {
        case .YELLOW: return "노랑"
        case .GREEN: return "초록"
        case .BLUE: return "파랑"
        }
    }
}

// MARK: - Edit Schedule View
struct EditScheduleView: View {
    let schedule: ScheduleItem
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String
    @State private var isAllDay: Bool
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedTag: ScheduleTag
    @State private var memo: String
    @State private var showTagPicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(schedule: ScheduleItem, onSave: @escaping () -> Void) {
        self.schedule = schedule
        self.onSave = onSave
        
        _title = State(initialValue: schedule.title)
        _isAllDay = State(initialValue: schedule.isAllDay)
        _selectedTag = State(initialValue: schedule.tag)
        _memo = State(initialValue: schedule.memo ?? "")
        
        // Parse dates
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        _startDate = State(initialValue: formatter.date(from: schedule.startAt) ?? Date())
        _endDate = State(initialValue: formatter.date(from: schedule.endAt) ?? Date())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Title Section with tag color dot
                        HStack(spacing: 12) {
                            TextField("제목", text: $title)
                                .font(Theme.Typography.bodyM)
                                .foregroundColor(Theme.Colors.text)
                            
                            Spacer()
                            
                            Button(action: {
                                showTagPicker.toggle()
                            }) {
                                Circle()
                                    .fill(selectedTagColor)
                                    .frame(width: 24, height: 24)
                            }
                            .popover(isPresented: $showTagPicker, arrowEdge: .top) {
                                TagColorPicker(selectedTag: $selectedTag, showPicker: $showTagPicker)
                                    .presentationCompactAdaptation(.popover)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)
                        
                        Divider()
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        // All-day toggle
                        HStack {
                            Image(systemName: "clock")
                                .font(.system(size: 20))
                                .foregroundColor(Theme.Colors.text)
                            
                            Text("하루 종일")
                                .font(Theme.Typography.bodyM)
                                .foregroundColor(Theme.Colors.text)
                            
                            Spacer()
                            
                            Toggle("", isOn: $isAllDay)
                                .labelsHidden()
                                .tint(Theme.Colors.mainYellow)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)
                        
                        Divider()
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Date selection with time picker
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack(spacing: 20) {
                                DatePicker("", selection: $startDate, displayedComponents: [.date])
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.Colors.text)
                                
                                DatePicker("", selection: $endDate, displayedComponents: [.date])
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            }
                            
                            // Time picker - only show when isAllDay is false
                            if !isAllDay {
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("시작시간")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(Color(hex: "#707070"))
                                        
                                        DatePicker("", selection: $startDate, displayedComponents: [.hourAndMinute])
                                            .labelsHidden()
                                            .datePickerStyle(.compact)
                                    }
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.Colors.text)
                                        .padding(.top, 20)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("종료시간")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(Color(hex: "#707070"))
                                        
                                        DatePicker("", selection: $endDate, displayedComponents: [.hourAndMinute])
                                            .labelsHidden()
                                            .datePickerStyle(.compact)
                                    }
                                    
                                    Spacer()
                                }
                                .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)
                        
                        Divider()
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Memo Section
                        ZStack(alignment: .topLeading) {
                            if memo.isEmpty {
                                Text("일정 관련 메모를 적어주세요")
                                    .font(Theme.Typography.bodyM)
                                    .foregroundColor(Color(hex: "#C4C4C4"))
                                    .padding(.horizontal, Theme.Spacing.lg)
                                    .padding(.top, 16)
                            }
                            
                            TextEditor(text: $memo)
                                .font(Theme.Typography.bodyM)
                                .foregroundColor(Theme.Colors.text)
                                .frame(height: 120)
                                .padding(.horizontal, Theme.Spacing.md)
                                .scrollContentBackground(.hidden)
                        }
                        .background(Theme.Colors.background)
                        
                        Spacer()
                        
                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(Theme.Typography.bodyXS)
                                .foregroundColor(.red)
                                .padding(.horizontal, Theme.Spacing.lg)
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                dismiss()
                            }) {
                                Text("닫기")
                                    .font(Theme.Typography.bodyM)
                                    .foregroundColor(Theme.Colors.text)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Theme.Colors.black, lineWidth: 1)
                                    )
                            }
                            .disabled(isSaving)
                            
                            Button(action: {
                                Task {
                                    await saveSchedule()
                                }
                            }) {
                                Text(isSaving ? "저장 중..." : "저장")
                                    .font(Theme.Typography.bodyM)
                                    .foregroundColor(Theme.Colors.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(title.isEmpty || isSaving ? Color(hex: "#D9D9D9") : Theme.Colors.mainYellow)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                            }
                            .disabled(title.isEmpty || isSaving)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.lg)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
            .navigationTitle("일정 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { 
                        dismiss() 
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
    
    private var selectedTagColor: Color {
        switch selectedTag {
        case .YELLOW: return Theme.Colors.mainYellow
        case .GREEN: return .green
        case .BLUE: return Theme.Colors.blue
        }
    }
    
    private func saveSchedule() async {
        guard let groupId = UserDefaults.standard.string(forKey: "groupId") else {
            errorMessage = "그룹 정보를 찾을 수 없습니다."
            return
        }
        
        // Validate dates
        if endDate < startDate {
            errorMessage = "종료 시간은 시작 시간보다 늦어야 합니다."
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        let request = PatchScheduleRequest(
            title: title,
            isAllDay: isAllDay,
            startAt: ScheduleAPIService.formatScheduleDateTime(startDate, isAllDay: isAllDay),
            endAt: ScheduleAPIService.formatScheduleDateTime(endDate, isAllDay: isAllDay),
            tag: selectedTag,
            remindNotificationAt: nil,
            memo: memo.isEmpty ? nil : memo
        )
        
        do {
            try await ScheduleAPIService.shared.updateSchedule(
                groupId: groupId,
                scheduleId: String(schedule.scheduleId),
                request: request
            )
            print("✅ Schedule updated")
            dismiss()
            onSave()
        } catch let error as APIError {
            print("❌ APIError: \(error)")
            errorMessage = error.localizedDescription
            isSaving = false
        } catch {
            print("❌ Unknown error: \(error)")
            errorMessage = "일정 저장에 실패했습니다: \(error.localizedDescription)"
            isSaving = false
        }
    }
}

// MARK: - Clear Background Helper
struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    CalendarView()
}

