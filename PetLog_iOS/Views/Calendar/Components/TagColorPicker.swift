//
//  TagColorPicker.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 11/15/25
//

import SwiftUI

struct TagColorPicker: View {
    @Binding var selectedTag: ScheduleTag
    @Binding var showPicker: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach([ScheduleTag.YELLOW, ScheduleTag.GREEN, ScheduleTag.BLUE], id: \.self) { tag in
                Button(action: {
                    selectedTag = tag
                    showPicker = false
                }) {
                    Circle()
                        .fill(tagColor(for: tag))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(tagColor(for: tag), lineWidth: selectedTag == tag ? 2.5 : 0)
                                .frame(width: 36, height: 36)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(Theme.Colors.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
    }
    
    private func tagColor(for tag: ScheduleTag) -> Color {
        switch tag {
        case .YELLOW: return Theme.Colors.mainYellow
        case .GREEN: return .green
        case .BLUE: return Theme.Colors.blue
        }
    }
    
    private func tagName(for tag: ScheduleTag) -> String {
        switch tag {
        case .YELLOW: return "노랑"
        case .GREEN: return "초록"
        case .BLUE: return "파랑"
        }
    }
}
