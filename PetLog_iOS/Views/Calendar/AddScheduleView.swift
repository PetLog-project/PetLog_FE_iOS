//
//  AddScheduleView.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 11/15/25
//

import SwiftUI

struct AddScheduleView: View {
    let currentDate: Date
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var isAllDay = false
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedTag: ScheduleTag = .YELLOW
    @State private var memo = ""
    @State private var reminderOption: ReminderOption = .tenMinutes
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showTagPicker = false
    
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
    
    init(currentDate: Date, onSave: @escaping () -> Void) {
        self.currentDate = currentDate
        self.onSave = onSave
        // Initialize dates based on current date
        _startDate = State(initialValue: currentDate)
        _endDate = State(initialValue: currentDate.addingTimeInterval(3600)) // 1 hour later
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
                    .onTapGesture {
                        showTagPicker = false
                    }
                
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
            print("❌ No groupId found")
            return
        }
        
        print("📝 Creating schedule for groupId: \(groupId)")
        
        // Validate dates
        if endDate < startDate {
            errorMessage = "종료 시간은 시작 시간보다 늦어야 합니다."
            print("❌ End date before start date")
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        // Calculate reminder time based on selected option
        let reminderTime: Date?
        if isAllDay {
            // For all-day events, set reminder at start of day minus reminder minutes
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: startDate)
            reminderTime = calendar.date(byAdding: .minute, value: -reminderOption.minutes, to: startOfDay)
        } else {
            // For timed events, subtract reminder minutes from start time
            reminderTime = Calendar.current.date(byAdding: .minute, value: -reminderOption.minutes, to: startDate)
        }
        
        let request = CreateScheduleRequest(
            title: title,
            isAllDay: isAllDay,
            startTime: ScheduleAPIService.formatScheduleDateTime(startDate, isAllDay: isAllDay),
            endTime: ScheduleAPIService.formatScheduleDateTime(endDate, isAllDay: isAllDay),
            tag: selectedTag,
            remindNotificationAt: reminderTime != nil ? ScheduleAPIService.formatScheduleDateTime(reminderTime!) : nil,
            memo: memo.isEmpty ? nil : memo
        )
        
        print("📤 Request: title=\(request.title), isAllDay=\(request.isAllDay), startTime=\(request.startTime), endTime=\(request.endTime), tag=\(request.tag.rawValue), reminder=\(request.remindNotificationAt ?? "nil"), memo=\(request.memo ?? "nil")")
        
        do {
            let scheduleId = try await ScheduleAPIService.shared.createSchedule(groupId: groupId, request: request)
            print("✅ Schedule created with ID: \(scheduleId)")
            
            // Schedule local notification if reminder time is set
            if let reminderTime = reminderTime, reminderTime > Date() {
                NotificationManager.shared.scheduleCalendarReminder(
                    scheduleId: scheduleId,
                    title: title,
                    remindNotificationAt: reminderTime
                )
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
