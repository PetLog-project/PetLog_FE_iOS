import SwiftUI

// MARK: - Custom Date Picker
struct CustomDatePicker: View {
    @Binding var date: Date
    @State private var showPicker = false
    
    var body: some View {
        Button(action: {
            showPicker.toggle()
        }) {
            Text(formattedDate)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Theme.Colors.text)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(hex: "#F5F7F8"))
                .cornerRadius(20)
        }
        .sheet(isPresented: $showPicker) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("취소") {
                        showPicker = false
                    }
                    .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Text("날짜 선택")
                        .font(Theme.Typography.boldM)
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Button("완료") {
                        showPicker = false
                    }
                    .foregroundColor(Theme.Colors.mainYellow)
                }
                .padding()
                
                Divider()
                
                // Picker
                DatePicker("", selection: $date, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    .padding()
                
                Spacer()
            }
            .presentationDetents([.medium])
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

// MARK: - Custom Time Picker
struct CustomTimePicker: View {
    @Binding var date: Date
    @State private var showPicker = false
    
    var body: some View {
        Button(action: {
            showPicker.toggle()
        }) {
            Text(formattedTime)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Theme.Colors.text)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(hex: "#F5F7F8"))
                .cornerRadius(20)
        }
        .sheet(isPresented: $showPicker) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("취소") {
                        showPicker = false
                    }
                    .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Text("시간 선택")
                        .font(Theme.Typography.boldM)
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Button("완료") {
                        showPicker = false
                    }
                    .foregroundColor(Theme.Colors.mainYellow)
                }
                .padding()
                
                Divider()
                
                // Picker
                DatePicker("", selection: $date, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.wheel)
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    .labelsHidden()
                    .padding()
                
                Spacer()
            }
            .presentationDetents([.medium])
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a hh:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}
