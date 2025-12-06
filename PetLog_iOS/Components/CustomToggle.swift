//
//  CustomToggle.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 12/6/25
//

import SwiftUI

struct CustomToggle: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                // Background capsule
                Capsule()
                    .fill(isOn ? Theme.Colors.mainYellow : Color(hex: "#F5F7F8"))
                    .frame(width: 60, height: 26)
                
                // Circle knob
                Circle()
                    .fill(Theme.Colors.white)
                    .frame(width: 18, height: 18)
                    .padding(4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomToggle(isOn: .constant(true))
        CustomToggle(isOn: .constant(false))
    }
    .padding()
}
