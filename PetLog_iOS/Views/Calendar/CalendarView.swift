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
        NavigationStack {
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
                
                // Navigation destinations
                NavigationLink(destination: AddScheduleView(currentDate: selectedDate) {
                    viewModel.clearCache()
                    Task {
                        await viewModel.loadSchedules(for: selectedDate)
                    }
                }, isActive: $showAddSchedule) {
                    EmptyView()
                }
                .hidden()
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
        NavigationLink(isActive: $showScheduleDetail) {
            if let schedule = selectedSchedule {
                ScheduleDetailView(schedule: schedule) {
                    // Clear cache and force reload after editing
                    viewModel.clearCache()
                    Task {
                        await viewModel.loadSchedules(for: selectedDate)
                    }
                }
            } else {
                EmptyView()
            }
        } label: {
            EmptyView()
        }
        .hidden()
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
            VStack(alignment: .leading, spacing: 12) {
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
                    ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Title with tag color dot
                        HStack(spacing: 12) {
                            Text(schedule.title)
                                .font(Theme.Typography.headingM)
                                .foregroundColor(Theme.Colors.text)
                            
                            Spacer()
                            
                            Circle()
                                .fill(tagColor)
                                .frame(width: 20, height: 20)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.lg)
                        
                        Divider()
                            .background(Color(hex: "#A9A9A9"))
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Date and Time info
                        HStack(spacing: 0) {
                            if schedule.isAllDay {
                                // All-day event - only dates
                                Text(formatDate(schedule.startAt))
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.Colors.text)
                                    .frame(maxWidth: .infinity)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.Colors.text)
                                    .padding(.horizontal, 20)
                                
                                Text(formatDate(schedule.endAt))
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.Colors.text)
                                    .frame(maxWidth: .infinity)
                            } else {
                                // Timed event - dates and times
                                VStack(alignment: .center, spacing: 12) {
                                    Text(formatDate(schedule.startAt))
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.Colors.text)
                                    Text(formatTime(schedule.startAt))
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.Colors.text)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.Colors.text)
                                    .padding(.horizontal, 20)
                                
                                VStack(alignment: .center, spacing: 12) {
                                    Text(formatDate(schedule.endAt))
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.Colors.text)
                                    Text(formatTime(schedule.endAt))
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.Colors.text)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.lg)
                        
                        Divider()
                            .background(Color(hex: "#A9A9A9"))
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Reminder info
                        if let remindTime = schedule.remindNotificationAt {
                            HStack(spacing: 12) {
                                Image("clock")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(Theme.Colors.text)
                                
                                Text("리마인드 시간 : \(formatReminderTime(remindTime))")
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.Colors.text)
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.lg)
                            
                            Divider()
                                .background(Color(hex: "#A9A9A9"))
                                .padding(.horizontal, Theme.Spacing.lg)
                        }
                        
                        // Memo
                        Text(schedule.memo?.isEmpty == false ? schedule.memo! : "일정 관련 메모를 적어주세요")
                            .font(.system(size: 16))
                            .foregroundColor(schedule.memo?.isEmpty == false ? Theme.Colors.text : Color(hex: "#A9A9A9"))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(20)
                            .frame(height: 250, alignment: .topLeading)
                            .background(Color(hex: "#F5F7F8"))
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        Spacer()
                            .frame(height: Theme.Spacing.lg)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            
            // Action buttons - bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: 48) {
                        Button(action: { showEditSheet = true }) {
                            VStack(spacing: 6) {
                                Image("icon_park_outline_write")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(Color(hex: "#707070"))
                                
                                Text("편집")
                                    .font(Theme.Typography.bodyM)
                                    .foregroundColor(Color(hex: "#707070"))
                            }
                        }
                        
                        Button(action: { showDeleteAlert = true }) {
                            VStack(spacing: 3) {
                                Image(systemName: "trash")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "#707070"))
                                
                                Text("삭제")
                                    .font(Theme.Typography.bodyM)
                                    .foregroundColor(Color(hex: "#707070"))
                            }
                        }
                    }
                    .padding(.trailing, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            
            NavigationLink(isActive: $showEditSheet) {
                EditScheduleView(schedule: schedule) {
                    showEditSheet = false
                    onUpdate()
                }
            } label: {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        dismiss()
                    }
                }
        )
        .alert("일정 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                Task { await deleteSchedule() }
            }
        } message: {
            Text("이 일정을 삭제하시겠습니까?")
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
            outputFormatter.dateFormat = "M월 d일 (E)"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        // Try ISO format without seconds (yyyy-MM-dd'T'HH:mm)
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = isoFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "M월 d일 (E)"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        // Try date-only format (yyyy-MM-dd)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = dateFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "M월 d일 (E)"
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
    
    // Format reminder time as relative time (e.g. "10분 전")
    private func formatReminderTime(_ dateTimeString: String) -> String {
        // Parse reminder time
        let formatterWithSeconds = DateFormatter()
        formatterWithSeconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatterWithSeconds.locale = Locale(identifier: "en_US_POSIX")
        
        var reminderDate: Date?
        if let date = formatterWithSeconds.date(from: dateTimeString) {
            reminderDate = date
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            reminderDate = formatter.date(from: dateTimeString)
        }
        
        // Parse schedule start time
        var scheduleStartDate: Date?
        if let date = formatterWithSeconds.date(from: schedule.startAt) {
            scheduleStartDate = date
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            scheduleStartDate = formatter.date(from: schedule.startAt)
        }
        
        guard let reminderDate = reminderDate, let scheduleStartDate = scheduleStartDate else {
            return dateTimeString
        }
        
        // Calculate time difference
        let interval = scheduleStartDate.timeIntervalSince(reminderDate)
        let minutes = Int(interval / 60)
        
        if minutes < 60 {
            return "\(minutes)분 전"
        } else if minutes < 1440 { // Less than 24 hours
            let hours = minutes / 60
            return "\(hours)시간 전"
        } else {
            let days = minutes / 1440
            return "\(days)일 전"
        }
    }
    
    private func deleteSchedule() async {
        guard let groupId = UserDefaults.standard.string(forKey: "groupId") else { return }
        isDeleting = true
        
        do {
            try await ScheduleAPIService.shared.deleteSchedule(
                groupId: groupId,
                scheduleId: String(schedule.scheduleId)
            )
            
            // Cancel local notification
            NotificationManager.shared.cancelCalendarReminder(scheduleId: String(schedule.scheduleId))
            
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
    @State private var reminderOption: ReminderOption = .tenMinutes
    @State private var showTagPicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    enum ReminderOption: String, CaseIterable {
        case tenMinutes = "10분 전"
        case thirtyMinutes = "30분 전"
        case oneHour = "1시간 전"
        case oneDay = "1일 전"
        
        var minutes: Int {
            switch self {
            case .tenMinutes: return 10
            case .thirtyMinutes: return 30
            case .oneHour: return 60
            case .oneDay: return 1440
            }
        }
    }
    
    init(schedule: ScheduleItem, onSave: @escaping () -> Void) {
        self.schedule = schedule
        self.onSave = onSave
        
        _title = State(initialValue: schedule.title)
        _isAllDay = State(initialValue: schedule.isAllDay)
        _selectedTag = State(initialValue: schedule.tag)
        _memo = State(initialValue: schedule.memo ?? "")
        
        // Parse dates - try with seconds first, then without
        func parseDate(_ dateString: String) -> Date {
            let formatterWithSeconds = DateFormatter()
            formatterWithSeconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatterWithSeconds.locale = Locale(identifier: "en_US_POSIX")
            
            if let date = formatterWithSeconds.date(from: dateString) {
                return date
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            return formatter.date(from: dateString) ?? Date()
        }
        
        _startDate = State(initialValue: parseDate(schedule.startAt))
        _endDate = State(initialValue: parseDate(schedule.endAt))
    }
    
    var body: some View {
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
                            
                            CustomToggle(isOn: $isAllDay)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)
                        
                        Divider()
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Date and Time selection
                        HStack(spacing: 0) {
                            if isAllDay {
                                // All-day: only dates side by side
                                CustomDatePicker(date: $startDate)
                                    .frame(maxWidth: .infinity)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.Colors.text)
                                    .padding(.horizontal, 20)
                                
                                CustomDatePicker(date: $endDate)
                                    .frame(maxWidth: .infinity)
                            } else {
                                // Timed: date and time stacked vertically on each side
VStack(alignment: .center, spacing: 12) {
                                    CustomDatePicker(date: $startDate)
                                    CustomTimePicker(date: $startDate)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.Colors.text)
                                    .padding(.horizontal, 20)
                                
VStack(alignment: .center, spacing: 12) {
                                    CustomDatePicker(date: $endDate)
                                    CustomTimePicker(date: $endDate)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.lg)
                        
                        Divider()
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Reminder Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack {
                                Image("clock")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(Theme.Colors.text)
                                
                                Text("리마인드 시간")
                                    .font(Theme.Typography.bodyM)
                                    .foregroundColor(Theme.Colors.text)
                            }
                            
                            VStack(spacing: 8) {
                                ForEach(ReminderOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        reminderOption = option
                                    }) {
                                        HStack {
                                            ZStack {
                                                Circle()
                                                    .stroke(reminderOption == option ? Theme.Colors.mainYellow : Color(hex: "#A9A9A9"), lineWidth: 2)
                                                    .frame(width: 20, height: 20)
                                                
                                                if reminderOption == option {
                                                    Circle()
                                                        .fill(Theme.Colors.mainYellow)
                                                        .frame(width: 12, height: 12)
                                                }
                                            }
                                            
                                            Text(option.rawValue)
                                                .font(Theme.Typography.bodyM)
                                                .foregroundColor(Theme.Colors.text)
                                            
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)
                        
                        Divider()
                            .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Memo Section
                        VStack(alignment: .leading, spacing: 10) {
                            ZStack(alignment: .topLeading) {
                                if memo.isEmpty {
                                    Text("일정 관련 메모를 적어주세요")
                                        .font(Theme.Typography.bodyM)
                                        .foregroundColor(Color(hex: "#C4C4C4"))
                                        .padding(20)
                                }
                                
                                TextEditor(text: $memo)
                                    .font(Theme.Typography.bodyM)
                                    .foregroundColor(Theme.Colors.text)
                                    .padding(20)
                                    .scrollContentBackground(.hidden)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: isAllDay ? 260 : 205, alignment: .topLeading)
                        .background(Color(red: 0.96, green: 0.97, blue: 0.97))
                        .padding(.horizontal, Theme.Spacing.lg)
                        
                        Spacer()
                        
                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(Theme.Typography.bodyXS)
                                .foregroundColor(.red)
                                .padding(.horizontal, Theme.Spacing.lg)
                        }
                        
                        // Action Buttons
                        HStack(spacing: 160) {
                            Button(action: {
                                dismiss()
                            }) {
                                HStack(alignment: .center, spacing: 10) {
                                    Text("닫기")
                                        .font(Theme.Typography.boldM)
                                        .foregroundColor(Theme.Colors.text)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(width: 100, height: 40, alignment: .center)
                                .background(Color.clear)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .inset(by: 0.5)
                                        .stroke(Theme.Colors.black, lineWidth: 1)
                                )
                            }
                            .disabled(isSaving)
                            
                            Button(action: {
                                Task {
                                    await saveSchedule()
                                }
                            }) {
                                HStack(alignment: .center, spacing: 10) {
                                    Text(isSaving ? "저장 중..." : "저장")
                                        .font(Theme.Typography.boldM)
                                        .foregroundColor(Theme.Colors.black)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(width: 100, height: 40, alignment: .center)
                                .background(title.isEmpty || isSaving ? Color(hex: "#D9D9D9") : Theme.Colors.mainYellow)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .inset(by: 0.5)
                                        .stroke(Theme.Colors.black, lineWidth: 1)
                                )
                            }
                            .disabled(title.isEmpty || isSaving)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.lg)
                }
                .padding(.top, Theme.Spacing.md)
            }
            .padding(.horizontal, 20)
            
            if showTagPicker {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { showTagPicker = false }
                
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 16) {
                            ForEach([ScheduleTag.YELLOW, ScheduleTag.GREEN, ScheduleTag.BLUE], id: \.self) { tag in
                                Button(action: {
                                    selectedTag = tag
                                    showTagPicker = false
                                }) {
                                    Circle()
                                        .fill(tagColorFor(tag))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(tagColorFor(tag), lineWidth: selectedTag == tag ? 2.5 : 0)
                                                .frame(width: 36, height: 36)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Theme.Colors.white)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
                        Spacer().frame(width: 50)
                    }
                    .padding(.top, 60)
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        dismiss()
                    }
                }
        )
    }
    
    private var selectedTagColor: Color {
        switch selectedTag {
        case .YELLOW: return Theme.Colors.mainYellow
        case .GREEN: return .green
        case .BLUE: return Theme.Colors.blue
        }
    }
    
    private func tagColorFor(_ tag: ScheduleTag) -> Color {
        switch tag {
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
        
        // Calculate reminder time based on selected option
        let reminderTime: Date?
        if isAllDay {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: startDate)
            reminderTime = calendar.date(byAdding: .minute, value: -reminderOption.minutes, to: startOfDay)
        } else {
            reminderTime = Calendar.current.date(byAdding: .minute, value: -reminderOption.minutes, to: startDate)
        }
        
        let request = PatchScheduleRequest(
            title: title,
            isAllDay: isAllDay,
            startTime: ScheduleAPIService.formatScheduleDateTime(startDate, isAllDay: isAllDay),
            endTime: ScheduleAPIService.formatScheduleDateTime(endDate, isAllDay: isAllDay),
            tag: selectedTag,
            remindNotificationAt: reminderTime != nil ? ScheduleAPIService.formatScheduleDateTime(reminderTime!) : "",
            memo: memo.isEmpty ? nil : memo
        )
        
        do {
            try await ScheduleAPIService.shared.updateSchedule(
                groupId: groupId,
                scheduleId: String(schedule.scheduleId),
                request: request
            )
            print("✅ Schedule updated")
            
            // Update local notification
            if let reminderTime = reminderTime, reminderTime > Date() {
                NotificationManager.shared.scheduleCalendarReminder(
                    scheduleId: String(schedule.scheduleId),
                    title: title,
                    remindNotificationAt: reminderTime
                )
            } else {
                // Cancel notification if no reminder or reminder is in the past
                NotificationManager.shared.cancelCalendarReminder(scheduleId: String(schedule.scheduleId))
            }
            
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

