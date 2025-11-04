import SwiftUI

struct NotesView: View {
    @Binding var isPresented: Bool
    @State private var notes: String = ""
    @State private var isEditing: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool
    
    private let characterLimit = 1000
    private let apiService = PetLogAPIService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            navigationBar
            
            // Content
            if isEditing {
                editingContent
            } else {
                if notes.isEmpty {
                    emptyContent
                } else {
                    readingContent
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.white)
        .onAppear {
            loadNotes()
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack {
            // Back button and title
            HStack(spacing: 12) {
                Button {
                    isPresented = false
                } label: {
                    Image("lucide_move_left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 19)
                        .foregroundColor(Theme.Colors.text)
                }
                
                Text("참고 사항")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
            }
            
            Spacer()
            
            // Edit/Cancel button
            if !isEditing {
                Button {
                    isEditing = true
                    isTextFieldFocused = true
                } label: {
                    Text("수정")
                        .font(Theme.Typography.bodyM)
                        .foregroundColor(Color(red: 0.66, green: 0.66, blue: 0.66))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(height: 60)
        .background(Theme.Colors.white)
    }
    
    // MARK: - Empty State
    private var emptyContent: some View {
        VStack {
            Text("참고 사항이 없습니다. 케어 시 참고해야 할 사항이 있다면 수정 버튼을 눌러 참고사항을 작성해주세요.")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.66, green: 0.66, blue: 0.66))
                .padding(20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Reading State
    private var readingContent: some View {
        ScrollView {
            Text(notes)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Editing State
    private var editingContent: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: $notes)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.text)
                .padding(20)
                .focused($isTextFieldFocused)
                .onChange(of: notes) { oldValue, newValue in
                    if newValue.count > characterLimit {
                        notes = String(newValue.prefix(characterLimit))
                    }
                }
            
            // Confirm button
            Button {
                saveNotes()
            } label: {
                Text("확인")
                    .font(Theme.Typography.boldM)
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 100, height: 40)
                    .background(Theme.Colors.mainYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.Colors.black, lineWidth: 1)
                    )
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    private func loadNotes() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let note = try await apiService.getNotes()
                await MainActor.run {
                    notes = note ?? ""
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    // If no notes exist (404), just show empty
                    notes = ""
                    isLoading = false
                }
            }
        }
    }
    
    private func saveNotes() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isLoading = true
        
        Task {
            do {
                // Update (send nil to delete)
                try await apiService.updateNotes(content: notes.isEmpty ? nil : notes)
                
                await MainActor.run {
                    isEditing = false
                    isTextFieldFocused = false
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "저장에 실패했습니다."
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Empty State") {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        var body: some View {
            NotesView(isPresented: $isPresented)
        }
    }
    return PreviewWrapper()
}
