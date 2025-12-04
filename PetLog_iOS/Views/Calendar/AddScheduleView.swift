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
                        
                        // Date selection with arrow
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack(spacing: 20) {
                                DatePicker("", selection: $startDate, displayedComponents: [.date])
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .environment(\.locale, Locale(identifier: "ko_KR"))
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.Colors.text)
                                
                                DatePicker("", selection: $endDate, displayedComponents: [.date])
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .environment(\.locale, Locale(identifier: "ko_KR"))
                            }
                            
                            // Time picker - only show when isAllDay is false
                            if !isAllDay {
                                HStack(spacing: 20) {
                                    // Start time picker
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("시작시간")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(Color(hex: "#707070"))
                                        
                                        DatePicker("", selection: $startDate, displayedComponents: [.hourAndMinute])
                                            .labelsHidden()
                                            .datePickerStyle(.compact)
                                            .environment(\.locale, Locale(identifier: "ko_KR"))
                                    }
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.Colors.text)
                                        .padding(.top, 20)
                                    
                                    // End time picker
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("종료시간")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(Color(hex: "#707070"))
                                        
                                        DatePicker("", selection: $endDate, displayedComponents: [.hourAndMinute])
                                            .labelsHidden()
                                            .datePickerStyle(.compact)
                                            .environment(\.locale, Locale(identifier: "ko_KR"))
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
                        
                        // Reminder Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack {
                                Image(systemName: "bell")
                                    .font(.system(size: 20))
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
                                            Circle()
                                                .strokeBorder(reminderOption == option ? Theme.Colors.mainYellow : Color(hex: "#D9D9D9"), lineWidth: 2)
                                                .background(
                                                    Circle()
                                                        .fill(reminderOption == option ? Theme.Colors.mainYellow : Color.clear)
                                                )
                                                .frame(width: 20, height: 20)
                                            
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
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
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
            }
            .navigationTitle("일정 추가")
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
