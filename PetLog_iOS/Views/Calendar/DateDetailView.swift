//
//  DateDetailView.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 11/15/25.
//

import SwiftUI

struct DateDetailView: View {
    let date: Date
    let schedules: [ScheduleItem]
    let onScheduleTap: (ScheduleItem) -> Void
    let onAddSchedule: () -> Void
    let onDismiss: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            // Semi-transparent background overlay covering entire screen
            Color.black.opacity(0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }
            
            // Modal content
            VStack(spacing: 0) {
                // Date header with dashed border
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        
                        Text(weekdayString)
                            .font(Theme.Typography.boldM)
                            .foregroundColor(Theme.Colors.text)
                        
                        Spacer()
                    }
                    .padding(.bottom, 12)
                    
                    // Dashed border
                    DashedLine()
                        .stroke(Color(hex: "#707070"), style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .frame(height: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Schedule list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(schedules) { schedule in
                            ModalScheduleCard(schedule: schedule) {
                                onScheduleTap(schedule)
                            }
                        }
                    }
                    .padding(4)
                }
                .padding(.top, 12)
                .padding(.horizontal, 20)
                
                // Add schedule button at bottom
                HStack(spacing: 20) {
                    Text("\(monthString) \(calendar.component(.day, from: date))일에 일정 추가")
                        .font(Theme.Typography.bodyM)
                        .foregroundColor(Color(hex: "#707070"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#F5F7F8"))
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .stroke(Theme.Colors.black, lineWidth: 1)
                        )
                    
                    Button(action: onAddSchedule) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.Colors.black)
                            .frame(width: 40, height: 40)
                            .background(Theme.Colors.mainYellow)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .frame(width: 320, height: 451)
            .background(Theme.Colors.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
    
    
    // MARK: - Helper Properties
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E요일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

// MARK: - Dashed Line Shape
struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

// MARK: - Modal Schedule Card (Figma design)
struct ModalScheduleCard: View {
    let schedule: ScheduleItem
    let onTap: () -> Void
    
    var body: some View {
                Button(action: onTap) {
                    HStack(spacing: 12) {
                        // Circular icon with tag color
                        ZStack {
                            Circle()
                                .fill(tagColor)
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: schedule.isAllDay ? "calendar" : "clock")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.black)
                        }
                        .padding(8)
                        .background(tagColor)
                        .clipShape(Circle())
                        
                        // Schedule info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(schedule.title)
                                .font(Theme.Typography.boldM)
                                .foregroundColor(Theme.Colors.text)
                                .lineLimit(1)
                            
                            Text(schedule.isAllDay ? "하루 종일" : startTimeString)
                                .font(Theme.Typography.boldXS)
                                .foregroundColor(schedule.isAllDay ? tagTextColor : tagColor)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(tagBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(tagBorderColor, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
    }
    
    private var tagColor: Color {
        switch schedule.tag {
        case .YELLOW: return Theme.Colors.mainYellow
        case .GREEN: return Color(hex: "#81C26C")
        case .BLUE: return Color(hex: "#5C9BFF")
        }
    }
    
    private var tagTextColor: Color {
        switch schedule.tag {
        case .YELLOW: return Color(hex: "#FF8E2C")
        case .GREEN: return Color(hex: "#81C26C")
        case .BLUE: return Color(hex: "#5C9BFF")
        }
    }
    
    private var tagBackgroundColor: Color {
        switch schedule.tag {
        case .YELLOW: return Color(hex: "#FFF8DA")
        case .GREEN: return Color(hex: "#F0FFEC")
        case .BLUE: return Color(hex: "#EBF1FF")
        }
    }
    
    private var tagBorderColor: Color {
        switch schedule.tag {
        case .YELLOW: return Color(hex: "#FF8E2C")
        case .GREEN: return Color(hex: "#81C26C")
        case .BLUE: return Color(hex: "#5C9BFF")
        }
    }
    
    private var startTimeString: String {
        // Extract time from ISO format: "yyyy-MM-dd'T'HH:mm:ss"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = formatter.date(from: schedule.startAt) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "a h:mm"
            timeFormatter.locale = Locale(identifier: "ko_KR")
            return timeFormatter.string(from: date)
        }
        
        // Fallback for date-only format
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = dateOnlyFormatter.date(from: schedule.startAt) {
            return "오전 12:00"
        }
        
        return schedule.startAt
    }
}

#Preview {
    DateDetailView(
        date: Date(),
        schedules: [],
        onScheduleTap: { _ in },
        onAddSchedule: { },
        onDismiss: { }
    )
}
