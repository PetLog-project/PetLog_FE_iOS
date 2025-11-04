import SwiftUI
import Combine

// MARK: - Activity Card Type
enum ActivityCardType {
    case feedingBefore(timeRemaining: String)
    case feedingTime
    case feedingAfter(timePassed: String)
    case waterBefore(timeRemaining: String)
    case waterTime
    case waterAfter(timePassed: String)
    case poop(count: Int)
}

// MARK: - Swipeable Activity Card Container
struct SwipeableActivityCards: View {
    let feedingData: Feeding
    let wateringData: Watering
    let poopData: Poop
    @Binding var showFeedingModal: Bool
    @Binding var showWateringModal: Bool
    @Binding var showPoopModal: Bool
    
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var feedingCompleted = false
    @State private var wateringCompleted = false
    @State private var poopCompleted = false
    @State private var currentTime = Date()
    
    // Updated memos and poop count
    @State private var feedingMemo: String
    @State private var wateringMemo: String
    @State private var poopMemo: String
    @State private var poopCount: Int
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    init(
        feedingData: Feeding,
        wateringData: Watering,
        poopData: Poop,
        showFeedingModal: Binding<Bool>,
        showWateringModal: Binding<Bool>,
        showPoopModal: Binding<Bool>
    ) {
        self.feedingData = feedingData
        self.wateringData = wateringData
        self.poopData = poopData
        self._showFeedingModal = showFeedingModal
        self._showWateringModal = showWateringModal
        self._showPoopModal = showPoopModal
        
        _feedingMemo = State(initialValue: feedingData.lastMemo)
        _wateringMemo = State(initialValue: wateringData.lastMemo)
        _poopMemo = State(initialValue: poopData.lastMemo)
        _poopCount = State(initialValue: poopData.todayPoopCount)
    }
    
    private var cards: [ActivityCardType] {
        let feedingCard = getFeedingCardType()
        let wateringCard = getWateringCardType()
        
        return [
            feedingCard,
            wateringCard,
            .poop(count: poopCount)
        ]
    }
    
    private func getFeedingCardType() -> ActivityCardType {
        if feedingCompleted {
            return .feedingBefore(timeRemaining: "6시간 00분")
        }
        
        let nextFeedingTime = feedingData.lastFeedingTime.addingTimeInterval(TimeInterval(feedingData.feedingCycle * 3600))
        let timeInterval = nextFeedingTime.timeIntervalSince(currentTime)
        
        if timeInterval > 0 {
            // Before feeding time - shouldn't show this initially, only after completion
            let hours = Int(timeInterval) / 3600
            let minutes = (Int(timeInterval) % 3600) / 60
            return .feedingBefore(timeRemaining: "\(hours)시간 \(String(format: "%02d", minutes))분")
        } else if timeInterval > -3600 {
            // Feeding time (within 1 hour of scheduled time)
            return .feedingTime
        } else {
            // After feeding time (more than 1 hour overdue)
            let overdue = abs(timeInterval)
            let hours = Int(overdue) / 3600
            let minutes = (Int(overdue) % 3600) / 60
            return .feedingAfter(timePassed: "\(hours)시간 \(String(format: "%02d", minutes))분")
        }
    }
    
    private func getWateringCardType() -> ActivityCardType {
        if wateringCompleted {
            return .waterBefore(timeRemaining: "6시간 00분")
        }
        
        let nextWateringTime = wateringData.lastWateringTime.addingTimeInterval(TimeInterval(wateringData.wateringCycle * 3600))
        let timeInterval = nextWateringTime.timeIntervalSince(currentTime)
        
        if timeInterval > 0 {
            // Before watering time
            let hours = Int(timeInterval) / 3600
            let minutes = (Int(timeInterval) % 3600) / 60
            return .waterBefore(timeRemaining: "\(hours)시간 \(String(format: "%02d", minutes))분")
        } else if timeInterval > -3600 {
            // Watering time (within 1 hour)
            return .waterTime
        } else {
            // After watering time
            let overdue = abs(timeInterval)
            let hours = Int(overdue) / 3600
            let minutes = (Int(overdue) % 3600) / 60
            return .waterAfter(timePassed: "\(hours)시간 \(String(format: "%02d", minutes))분")
        }
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    ForEach(cards.indices, id: \.self) { index in
                        ActivityCardView(
                            cardType: cards[index],
                            feedingData: feedingData,
                            wateringData: wateringData,
                            poopData: poopData,
                            feedingMemo: feedingMemo,
                            wateringMemo: wateringMemo,
                            poopMemo: poopMemo,
                            onFeedingButtonTap: { showFeedingModal = true },
                            onWateringButtonTap: { showWateringModal = true },
                            onPoopButtonTap: { showPoopModal = true }
                        )
                        .frame(width: 251, height: 328)
                        .offset(x: CGFloat(index - currentIndex) * (251 + 20) + dragOffset)
                        .opacity(index == currentIndex ? 1.0 : 0.6)
                        .scaleEffect(index == currentIndex ? 1.0 : 0.9)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentIndex)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
                    }
                }
                .frame(width: geometry.size.width, height: 328)
                .onReceive(timer) { _ in
                    currentTime = Date()
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width < -threshold && currentIndex < cards.count - 1 {
                                currentIndex += 1
                            } else if value.translation.width > threshold && currentIndex > 0 {
                                currentIndex -= 1
                            }
                            dragOffset = 0
                        }
                )
                .onTapGesture {
                    // Optional: tap to go to next card
                    if currentIndex < cards.count - 1 {
                        currentIndex += 1
                    }
                }
            }
        }
    }
}

// MARK: - Individual Activity Card View
struct ActivityCardView: View {
    let cardType: ActivityCardType
    let feedingData: Feeding
    let wateringData: Watering
    let poopData: Poop
    let feedingMemo: String
    let wateringMemo: String
    let poopMemo: String
    let onFeedingButtonTap: () -> Void
    let onWateringButtonTap: () -> Void
    let onPoopButtonTap: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(Theme.Colors.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Theme.Colors.black, lineWidth: 1)
                )
            
            VStack(spacing: 24) {
                // Icon
                iconView
                    .frame(height: 30)
                
                // Title
                titleView
                
                // User info
                userInfoView
                    .frame(width: 208)
                
                Spacer()
                
                // Action button (if applicable)
                if hasActionButton {
                    actionButton
                }
            }
            .padding(20)
        }
        .frame(width: 251, height: 328)
    }
    
    @ViewBuilder
    private var iconView: some View {
        switch cardType {
        case .feedingBefore:
            // Full bowl rice icon (밥 시간 전 - after feeding completed)
            Image("bx_bowl_rice")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(Theme.Colors.text)
        case .feedingTime, .feedingAfter:
            // Empty bowl icon (밥 시간 or 밥 시간 후 - needs feeding)
            Image("empty_bowl")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(Theme.Colors.text)
        case .waterBefore, .waterAfter:
            // Full blue water drop (물 시간 전 or 물 시간 후)
            Image("water-drop")
                .resizable()
                .scaledToFit()
                .frame(width: 27, height: 27)
        case .waterTime:
            // Empty water outline (물 시간 - needs watering now)
            Image("empty_water")
                .resizable()
                .scaledToFit()
                .frame(width: 27, height: 27)
        case .poop:
            // Toilet icon from Figma
            Image("toilet")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }
    
    @ViewBuilder
    private var titleView: some View {
        switch cardType {
        case .feedingBefore(let time):
            VStack(spacing: 4) {
                Text("다음 밥 시간까지")
                    .font(Theme.Typography.boldM)
                    .foregroundColor(Theme.Colors.text)
                Text(time)
                    .font(Theme.Typography.boldM)
                    .foregroundColor(Theme.Colors.blue)
                Text("남았어요")
                    .font(Theme.Typography.boldM)
                    .foregroundColor(Theme.Colors.text)
            }
        case .feedingTime:
            Text("ㅇㅇ이 밥을 챙겨주세요")
                .font(Theme.Typography.boldM)
                .foregroundColor(Theme.Colors.text)
        case .feedingAfter(let time):
            Text("급여 시간부터 \(time) 지났어요")
                .font(Theme.Typography.boldM)
                .foregroundColor(Color(red: 1.0, green: 0.38, blue: 0.38)) // warning color
                .multilineTextAlignment(.center)
        case .waterBefore(let time):
            VStack(spacing: 4) {
                Text("다음 물 교체까지")
                    .font(Theme.Typography.boldM)
                    .foregroundColor(Theme.Colors.text)
                Text(time)
                    .font(Theme.Typography.boldM)
                    .foregroundColor(Theme.Colors.blue)
                Text("남았어요")
                    .font(Theme.Typography.boldM)
                    .foregroundColor(Theme.Colors.text)
            }
        case .waterTime:
            Text("물을 교체 할 시간이에요")
                .font(Theme.Typography.boldM)
                .foregroundColor(Theme.Colors.text)
        case .waterAfter(let time):
            Text("교체 시간부터 \(time) 지났어요")
                .font(Theme.Typography.boldM)
                .foregroundColor(Color(red: 1.0, green: 0.38, blue: 0.38))
                .multilineTextAlignment(.center)
        case .poop(let count):
            Text("배변 횟수: \(count)번")
                .font(Theme.Typography.boldM)
                .foregroundColor(Theme.Colors.text)
        }
    }
    
    @ViewBuilder
    private var userInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(userLabel)
                    .font(Theme.Typography.bodyM)
                    .foregroundColor(Theme.Colors.text)
                Text(userName)
                    .font(Theme.Typography.bodyM)
                    .foregroundColor(Theme.Colors.text)
                Spacer()
            }
            
            HStack(spacing: 8) {
                Text("참고 사항 :")
                    .font(Theme.Typography.bodyM)
                    .foregroundColor(Theme.Colors.text)
                Text(note)
                    .font(Theme.Typography.bodyM)
                    .foregroundColor(Theme.Colors.text)
                Spacer()
            }
        }
    }
    
    private var userLabel: String {
        switch cardType {
        case .poop:
            return "보호자 :"
        default:
            return "급여자 :"
        }
    }
    
    private var userName: String {
        switch cardType {
        case .feedingBefore, .feedingTime, .feedingAfter:
            return feedingData.lastCheckerName
        case .waterBefore, .waterTime, .waterAfter:
            return wateringData.lastCheckerName
        case .poop:
            return poopData.lastCheckerName
        }
    }
    
    private var note: String {
        switch cardType {
        case .feedingBefore, .feedingTime, .feedingAfter:
            return feedingMemo
        case .waterBefore, .waterTime, .waterAfter:
            return wateringMemo
        case .poop:
            return poopMemo
        }
    }
    
    private var hasActionButton: Bool {
        switch cardType {
        case .feedingTime, .feedingAfter, .waterTime, .waterAfter, .poop:
            return true
        default:
            return false
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        Button {
            handleAction()
        } label: {
            Text(actionButtonText)
                .font(Theme.Typography.boldM)
                .foregroundColor(Theme.Colors.text)
                .frame(width: 180, height: 40)
                .background(Theme.Colors.mainYellow)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.Colors.black, lineWidth: 1)
                )
        }
    }
    
    private var actionButtonText: String {
        switch cardType {
        case .feedingTime, .feedingAfter:
            return "밥 주기"
        case .waterTime, .waterAfter:
            return "물 교체 하기"
        case .poop:
            return "배변 체크"
        default:
            return ""
        }
    }
    
    private func handleAction() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        switch cardType {
        case .feedingTime, .feedingAfter:
            onFeedingButtonTap()
        case .waterTime, .waterAfter:
            onWateringButtonTap()
        case .poop:
            onPoopButtonTap()
        default:
            break
        }
    }
}
