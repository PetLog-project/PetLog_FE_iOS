//
//  TestView.swift
//  PetLog_iOS
//
//  Created by Dongha Ryu on 10/22/25.
//

import SwiftUI

struct TestView: View {
    // Reference width from iPhone 16 Pro
    private let referenceWidth: CGFloat = 430
    private var scale: CGFloat { UIScreen.main.bounds.width / referenceWidth }
    private var safeArea: UIEdgeInsets {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.safeAreaInsets }
            .first ?? .zero
    }

    var body: some View {
        ZStack {
            Color(hex: "#FDFDFB").ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Top curved header
                ZStack(alignment: .top) {
                    CurvedHeaderShapes()
                        .fill(Color(hex: "#FFD93D"))
                        .frame(height: 240 * scale)

                    HStack {
                        Text("반려기록")
                            .font(.system(size: 20 * scale, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                        Spacer()
                        HStack(spacing: 16 * scale) {
                            Image("ic_share")
                                .resizable()
                                .frame(width: 22 * scale, height: 22 * scale)
                            Image("ic_settings")
                                .resizable()
                                .frame(width: 22 * scale, height: 22 * scale)
                        }
                    }
                    .padding(.horizontal, 24 * scale)
                    .padding(.top, safeArea.top + 12 * scale)
                }
                .frame(height: 240 * scale)
                .overlay(
                    Image("pet_photo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120 * scale, height: 120 * scale)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4 * scale))
                        .offset(y: 60 * scale)
                )
                .padding(.bottom, 60 * scale)

                // MARK: Pet Info
                VStack(spacing: 4 * scale) {
                    Text("몽키")
                        .font(.system(size: 20 * scale, weight: .bold))
                    HStack(spacing: 16 * scale) {
                        InfoItem(label: "나이", value: "1살", scale: scale)
                        InfoItem(label: "몸무게", value: "3 kg", scale: scale)
                        InfoItem(label: "종", value: "말티즈", scale: scale)
                    }
                }
                .padding(.bottom, 24 * scale)

                // MARK: Scroll Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16 * scale) {
                        CareCardView(scale: scale)
                        CareCardView(title: "배변", description: "배변 기록 없음", scale: scale)
                        CareCardView(title: "미용", description: "10월 24일 오전 11시 예약", scale: scale)
                    }
                    .padding(.horizontal, 20 * scale)
                    .padding(.bottom, 100 * scale)
                }

                Spacer(minLength: 0)

                // MARK: Bottom Nav
                Divider()
                BottomNav(scale: scale)
                    .padding(.bottom, safeArea.bottom + 4 * scale)
                    .background(Color.white.shadow(color: .gray.opacity(0.1), radius: 4))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Components

struct InfoItem: View {
    let label: String
    let value: String
    let scale: CGFloat
    var body: some View {
        VStack(spacing: 3 * scale) {
            Text(label)
                .font(.system(size: 12 * scale))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 14 * scale, weight: .semibold))
                .foregroundColor(.black)
        }
    }
}

struct CareCardView: View {
    var title: String = "산책"
    var description: String = "오늘 산책을 완료해주세요"
    var scale: CGFloat
    var body: some View {
        VStack(spacing: 10 * scale) {
            Image("ic_paw")
                .resizable()
                .frame(width: 32 * scale, height: 32 * scale)
            Text(title)
                .font(.system(size: 16 * scale, weight: .semibold))
                .foregroundColor(.black)
            Text(description)
                .font(.system(size: 13 * scale))
                .foregroundColor(.gray)
            Button("완료하기") { }
                .font(.system(size: 14 * scale, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10 * scale)
                .background(Color(hex: "#FFD93D"))
                .cornerRadius(8 * scale)
        }
        .padding(20 * scale)
        .background(Color.white)
        .cornerRadius(16 * scale)
        .shadow(color: .gray.opacity(0.05), radius: 3 * scale, y: 1 * scale)
    }
}

struct BottomNav: View {
    var scale: CGFloat
    var body: some View {
        HStack {
            NavItem(icon: "ic_home", label: "홈", selected: true, scale: scale)
            Spacer()
            NavItem(icon: "ic_record", label: "기록", scale: scale)
            Spacer()
            NavItem(icon: "ic_stats", label: "통계", scale: scale)
            Spacer()
            NavItem(icon: "ic_settings", label: "설정", scale: scale)
        }
        .padding(.horizontal, 32 * scale)
        .padding(.vertical, 10 * scale)
    }
}

struct NavItem: View {
    let icon: String
    let label: String
    var selected: Bool = false
    let scale: CGFloat
    var body: some View {
        VStack(spacing: 4 * scale) {
            Image(icon)
                .resizable()
                .renderingMode(.template)
                .frame(width: 22 * scale, height: 22 * scale)
                .foregroundColor(selected ? Color(hex: "#FFD93D") : .gray)
            Text(label)
                .font(.system(size: 11 * scale, weight: .medium))
                .foregroundColor(selected ? Color(hex: "#FFD93D") : .gray)
        }
    }
}

struct CurvedHeaderShapes: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.6))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.6),
            control: CGPoint(x: rect.width / 2, y: rect.height * 1.1)
        )
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.closeSubpath()
        return path
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }
}

#Preview {
    TestView()
}

