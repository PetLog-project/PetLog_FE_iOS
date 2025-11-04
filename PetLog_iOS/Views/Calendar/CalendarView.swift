//
//  CalendarView.swift
//  PetLog_iOS
//
//  Created by Dongha Ryu on 10/31/25.
//

import SwiftUI

struct CalendarView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.primary)
            
            Text("Calendar")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.text)
            
            Text("Coming Soon")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CalendarView()
}
