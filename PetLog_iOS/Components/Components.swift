import SwiftUI

// MARK: - Figma Profile Header
struct FigmaProfileHeader: View {
    let imageURL: URL?
    @Binding var name: String
    @Binding var age: String
    @Binding var weight: Double
    @Binding var gender: Gender?
    @Binding var showEditPopup: Bool
    
    var body: some View {
        ZStack(alignment: .top) {
            // Yellow curved background
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height: CGFloat = 220
                    
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: width, y: 0))
                    path.addLine(to: CGPoint(x: width, y: height - 60))
                    
                    // Smooth curve at bottom
                    path.addQuadCurve(
                        to: CGPoint(x: 0, y: height - 60),
                        control: CGPoint(x: width/2, y: height + 40)
                    )
                    path.closeSubpath()
                }
                .fill(Theme.Colors.mainYellow)
            }
            .frame(height: 220)
            
            // Content layer
            VStack(spacing: 0) {
                Spacer().frame(height: 60)
                
                // Pet image
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 120, height: 120)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    case .failure:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                    @unknown default:
                        EmptyView()
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Theme.Colors.white, lineWidth: 10)
                        .frame(width: 140, height: 140)
                )
                
                Spacer().frame(height: 12)
                
                // Pet name with edit icon
                Button {
                    showEditPopup = true
                } label: {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(Theme.Typography.headingL)
                            .foregroundColor(Theme.Colors.text)
                        
                        Image("icon_park_outline_write")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Theme.Colors.text)
                    }
                }
                
                Spacer().frame(height: 16)
                
                // Pet stats
                HStack(spacing: 0) {
                    Spacer()
                    
                    // Age
                    VStack(spacing: 8) {
                        Text("나이")
                            .font(Theme.Typography.boldM)
                            .foregroundColor(Theme.Colors.text)
                        Text(age)
                            .font(Theme.Typography.bodyM)
                            .foregroundColor(Theme.Colors.text)
                    }
                    
                    Spacer()
                    
                    // Weight
                    VStack(spacing: 8) {
                        Text("몸무게")
                            .font(Theme.Typography.boldM)
                            .foregroundColor(Theme.Colors.text)
                        Text(String(format: "%.1fkg", weight))
                            .font(Theme.Typography.bodyM)
                            .foregroundColor(Theme.Colors.text)
                    }
                    
                    Spacer()
                    
                    // Gender
                    VStack(spacing: 8) {
                        Text("성별")
                            .font(Theme.Typography.boldM)
                            .foregroundColor(Theme.Colors.text)
                        Image(gender == .female ? "ic_baseline_female" : "ic_baseline_male")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Theme.Colors.text)
                    }
                    .frame(width: 25)
                    
                    Spacer()
                }
                .frame(maxWidth: 181)
                
                Spacer().frame(height: 16)
            }
        }
    }
}

// MARK: - Curved Header Shape
struct CurvedHeaderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start from top left
        path.move(to: CGPoint(x: 0, y: 0))
        // Line to top right
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        // Line down
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 100))
        // Curve to bottom left
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - 100),
            control: CGPoint(x: rect.midX, y: rect.maxY + 50)
        )
        // Close path
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Figma Main Feeding Card
struct FigmaMainFeedingCard: View {
    let petName: String
    let lastFeeder: String
    let note: String
    
    var body: some View {
        ZStack {
            // Card background with border
            RoundedRectangle(cornerRadius: 30)
                .fill(Theme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                )
            
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                
                // Mask icon from Figma
                Image("Mask_group")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 16)
                
                Spacer().frame(height: 24)
                
                // Main title - 14px Pretendard Bold
                Text("\(petName) 밥을 챙겨주세요")
                    .font(Theme.Typography.boldM)
                    .foregroundColor(Theme.Colors.text)
                    .multilineTextAlignment(.center)
                
                Spacer().frame(height: 24)
                
                // User info section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("급여자 :")
                            .font(Theme.Typography.bodyM)
                            .foregroundColor(Theme.Colors.text)
                        Text(lastFeeder)
                            .font(Theme.Typography.bodyM)
                            .foregroundColor(Theme.Colors.text)
                        Spacer()
                    }
                    .frame(height: 17)
                    
                    HStack(spacing: 8) {
                        Text("참고 사항 :")
                            .font(Theme.Typography.bodyM)
                            .foregroundColor(Theme.Colors.text)
                        Text(note)
                            .font(Theme.Typography.bodyM)
                            .foregroundColor(Theme.Colors.text)
                        Spacer()
                    }
                    .frame(height: 17)
                }
                .frame(width: 208)
                
                Spacer()
                
                // Feed button - 180x40, positioned at bottom
                Button {
                    // Feed action
                } label: {
                    Text("밥 주기")
                        .font(Theme.Typography.boldM)
                        .foregroundColor(Theme.Colors.text)
                        .frame(width: 168, height: 24) // Text content area
                }
                .frame(width: 180, height: 40)
                .background(Theme.Colors.mainYellow)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                )
                
                Spacer().frame(height: 20)
            }
        }
        .frame(width: 251, height: 328) // Exact Figma dimensions
    }
}

// MARK: - Figma Small Activity Card  
struct FigmaSmallActivityCard: View {
    let timeRemaining: String
    let lastFeeder: String
    let note: String
    
    var body: some View {
        ZStack {
            // Card background with border
            RoundedRectangle(cornerRadius: 30)
                .fill(Theme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                )
            
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                
                
                Spacer().frame(height: 24)
                
                // Time remaining text - 10px Pretendard Bold with blue highlight
                HStack(spacing: 0) {
                    Text("다음 밥 시간까지 ")
                        .font(Theme.Typography.boldXS)
                        .foregroundColor(Theme.Colors.text)
                    Text(timeRemaining)
                        .font(Theme.Typography.boldXS)
                        .foregroundColor(Theme.Colors.blue)
                    Text(" 남았어요")
                        .font(Theme.Typography.boldXS)
                        .foregroundColor(Theme.Colors.text)
                }
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                
                Spacer().frame(height: 24)
                
                // User info section - 10px Pretendard Regular
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("급여자 :")
                            .font(Theme.Typography.bodyXS)
                            .foregroundColor(Theme.Colors.text)
                        Text(lastFeeder)
                            .font(Theme.Typography.bodyXS)
                            .foregroundColor(Theme.Colors.text)
                        Spacer()
                    }
                    .frame(height: 17)
                    
                    HStack(spacing: 8) {
                        Text("참고 사항 :")
                            .font(Theme.Typography.bodyXS)
                            .foregroundColor(Theme.Colors.text)
                        Text(note)
                            .font(Theme.Typography.bodyXS)
                            .foregroundColor(Theme.Colors.text)
                        Spacer()
                    }
                    .frame(height: 17)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, 15)
        }
        .frame(width: 180, height: 284) // Exact Figma dimensions
    }
}

// MARK: - Original Profile Card (keeping for compatibility)
struct ProfileCard: View {
    let imageURL: URL?
    let name: String
    let age: String
    let weight: Double
    let gender: Gender?
    @State private var isPressed = false
    
    var body: some View {
        Button {
            hapticFeedback()
        } label: {
            HStack(spacing: Theme.Spacing.lg) {
                ProfileImageView(url: imageURL)
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(name)
                        .font(Theme.Typography.title)
                        .foregroundColor(.white)
                    
                    HStack(spacing: Theme.Spacing.lg) {
                        InfoPill(icon: "calendar", text: age, color: .white.opacity(0.9))
                        
                        InfoPill(icon: "scalemass", text: String(format: "%.1fkg", weight), color: .white.opacity(0.9))
                        
                        if let gender = gender {
                            InfoPill(icon: gender == .male ? "person" : "person.fill", text: gender.rawValue, color: .white.opacity(0.9))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .animation(Theme.Animation.bounce, value: isPressed)
            }
        }
        .accessibilityLabel("Pet profile for \(name)")
        .accessibilityHint("Double tap to view more details")
        .accessibilityValue("Age: \(age), Weight: \(weight), Gender: \(gender?.rawValue ?? "Unknown")")
        .primaryCardStyle()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.Animation.quick, value: isPressed)
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Enhanced Profile Image
struct ProfileImageView: View {
    let url: URL?
    
    var body: some View {
        Group {
            if let url = url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "photo.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            } else {
                Image(systemName: "pawprint.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(width: Theme.Size.profileImageLarge, height: Theme.Size.profileImageLarge)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(.white.opacity(0.3), lineWidth: 3)
        )
    }
}

// MARK: - Activity Card Component
struct ActivityCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: String
    let lastUpdate: String
    let status: ActivityStatus
    @State private var isPressed = false
    
    var body: some View {
        Button {
            hapticFeedback()
        } label: {
            HStack(spacing: Theme.Spacing.lg) {
                // Icon Section
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack {
                        Text(title)
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.text)
                        
                        Spacer()
                        
                        StatusIndicator(status: status)
                    }
                    
                    Text(lastUpdate)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    if content != "-" {
                        Text(content)
                            .font(Theme.Typography.callout)
                            .foregroundColor(Theme.Colors.text)
                            .lineLimit(2)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
        }
        .accessibilityLabel("\(title) activity")
        .accessibilityValue("\(content != "-" ? content : "No data"), Last updated: \(lastUpdate), Status: \(accessibilityStatus(status))")
        .accessibilityHint("Double tap to view more details or update this activity")
        .cardStyle()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.Animation.quick, value: isPressed)
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Activity Status
enum ActivityStatus {
    case good, warning, attention, neutral
    
    var color: Color {
        switch self {
        case .good: return Theme.Colors.success
        case .warning: return Theme.Colors.warning
        case .attention: return Theme.Colors.danger
        case .neutral: return Theme.Colors.secondaryText
        }
    }
    
    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .attention: return "exclamationmark.circle.fill"
        case .neutral: return "circle.fill"
        }
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let status: ActivityStatus
    
    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: status.icon)
                .font(.caption)
                .foregroundColor(status.color)
        }
    }
}

// MARK: - Info Pill Component
struct InfoPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(Theme.Typography.footnote)
        }
        .foregroundColor(color)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(color.opacity(0.2))
        .clipShape(Capsule())
    }
}

// MARK: - Enhanced Date Formatters
struct DateFormatters {
    static let userFriendly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    static func timeAgo(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
    
    static func formatted(_ date: Date) -> String {
        userFriendly.string(from: date)
    }
}

// MARK: - Press Events Extension
struct PressEvents: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        onPress()
                    })
                    .onEnded({ _ in
                        onRelease()
                    })
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Bottom Navigation
struct FigmaBottomNavigation: View {
    @Binding var selectedTab: Int
    @Binding var showNotesView: Bool
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Record tab
            BottomNavItem(
                isSelected: selectedTab == 0,
                icon: "lucide_book_marked",
                iconSize: 24
            ) {
                guard !isAnimating else { return }
                isAnimating = true
                showNotesView = false
                selectedTab = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isAnimating = false
                }
            }
            
            // Home tab
            BottomNavItem(
                isSelected: selectedTab == 1,
                icon: "tabler_home",
                iconSize: 30
            ) {
                guard !isAnimating else { return }
                isAnimating = true
                showNotesView = false
                selectedTab = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isAnimating = false
                }
            }
            
            // Calendar tab
            BottomNavItem(
                isSelected: selectedTab == 2,
                icon: "lucide_calendar",
                iconSize: 30
            ) {
                guard !isAnimating else { return }
                isAnimating = true
                showNotesView = false
                selectedTab = 2
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isAnimating = false
                }
            }
        }
        .frame(height: 60)
        .background(Theme.Colors.white)
    }
}

// MARK: - Bottom Nav Item
struct BottomNavItem: View {
    let isSelected: Bool
    let icon: String
    let iconSize: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Top bar indicator - only this animates
                Rectangle()
                    .fill(isSelected ? Theme.Colors.mainYellow : Color.clear)
                    .frame(height: 4)
                
                Spacer()
                
                // Icon
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
            }
            .animation(.easeInOut(duration: 0.4), value: isSelected)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - App Header
struct FigmaAppHeader: View {
    @Binding var showSharePopup: Bool
    @Binding var showNotesView: Bool
    @Binding var showJoinGroupView: Bool
    let isWhiteBackground: Bool
    
    var body: some View {
        HStack {
            Text("반려기록")
                .font(Theme.Typography.headingL)
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            HStack(spacing: Theme.Spacing.xl) {
                Button {
                    showNotesView = true
                } label: {
                    Image("octicon_mortar_board_24")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Theme.Colors.text)
                }
                
                Button {
                    showSharePopup = true
                } label: {
                    Image("solar_share_linear")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Theme.Colors.text)
                }
                
                Button {
                    print("DEBUG: Join Group button tapped")
                    showJoinGroupView = true
                } label: {
                    Image("uil_setting")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Theme.Colors.text)
                }
            }
        }
        .frame(height: 60)
        .padding(.horizontal, Theme.Spacing.xl)
        .background(isWhiteBackground ? Theme.Colors.white : Theme.Colors.mainYellow)
    }
}

// MARK: - Accessibility Helpers
func accessibilityStatus(_ status: ActivityStatus) -> String {
    switch status {
    case .good: return "Good"
    case .warning: return "Needs attention"
    case .attention: return "Requires immediate attention"
    case .neutral: return "Normal"
    }
}

