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
        VStack(spacing: Theme.Spacing.md) {
            ForEach([ScheduleTag.YELLOW, ScheduleTag.GREEN, ScheduleTag.BLUE], id: \.self) { tag in
                Button(action: {
                    selectedTag = tag
                    showPicker = false
                }) {
                    HStack(spacing: Theme.Spacing.md) {
                        Circle()
                            .fill(tagColor(for: tag))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(selectedTag == tag ? Theme.Colors.black : Color.clear, lineWidth: 2)
                            )
                        
                        Text(tagName(for: tag))
                            .font(Theme.Typography.bodyM)
                            .foregroundColor(Theme.Colors.text)
                        
                        Spacer()
                        
                        if selectedTag == tag {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.mainYellow)
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .background(selectedTag == tag ? Theme.Colors.mainYellow.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(Theme.Spacing.md)
        .frame(width: 200)
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
