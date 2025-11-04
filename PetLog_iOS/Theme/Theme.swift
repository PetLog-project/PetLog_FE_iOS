import SwiftUI

struct Theme {
    // MARK: - Figma Design System Colors
    struct Colors {
        // Main Yellow from Figma
        static let mainYellow = Color(red: 1.0, green: 0.843, blue: 0.216) // #FFD737
        static let primary = mainYellow
        
        // Figma Text Colors
        static let black = Color(red: 0.118, green: 0.118, blue: 0.118) // #1E1E1E
        static let white = Color(red: 0.992, green: 0.992, blue: 0.984) // #FDFDFB
        
        // Figma Accent Colors
        static let blue = Color(red: 0.361, green: 0.608, blue: 1.0) // #5C9BFF
        
        // UI Colors
        static let text = black
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)
        static let background = white
        static let cardBackground = white
        
        // Activity Colors (keeping existing for compatibility)
        static let feeding = mainYellow
        static let watering = blue
        static let health = Color(red: 0.9, green: 0.4, blue: 0.6)
        
        // Status Colors (compatibility)
        static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)
        static let danger = Color(red: 1.0, green: 0.3, blue: 0.3)
        
        // Border Colors
        static let cardBorder = black
    }
    
    // MARK: - Figma Typography (Pretendard)
    struct Typography {
        // Heading Large - 24px Pretendard SemiBold
        static let headingL: Font = .system(size: 24, weight: .semibold, design: .default)
        
        // Bold Medium - 14px Pretendard Bold
        static let boldM: Font = .system(size: 14, weight: .bold, design: .default)
        
        // Body Medium - 14px Pretendard Regular
        static let bodyM: Font = .system(size: 14, weight: .regular, design: .default)
        
        // Bold Extra Small - 10px Pretendard Bold
        static let boldXS: Font = .system(size: 10, weight: .bold, design: .default)
        
        // Body Extra Small - 10px Pretendard Regular
        static let bodyXS: Font = .system(size: 10, weight: .regular, design: .default)
        
        // Compatibility aliases
        static let title = headingL
        static let headline = boldM
        static let body = bodyM
        static let callout = bodyM
        static let caption = boldXS
        static let footnote = bodyXS
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Figma Card Styling
    struct Card {
        static let cornerRadius: CGFloat = 30 // Figma uses 30px radius
        static let padding: CGFloat = 20
        
        // Figma style with border
        static func style<Content: View>(_ content: Content) -> some View {
            content
                .padding(padding)
                .background(Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Colors.cardBorder, lineWidth: 1)
                )
        }
        
        // Yellow header style for profile section
        static func yellowHeaderStyle<Content: View>(_ content: Content) -> some View {
            content
                .background(Colors.mainYellow)
        }
    }
    
    // MARK: - Sizing
    struct Size {
        static let profileImageLarge: CGFloat = 80
        static let profileImage: CGFloat = 60
        static let icon: CGFloat = 24
        static let iconSmall: CGFloat = 16
        static let button: CGFloat = 44
        static let cardMinHeight: CGFloat = 120
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick: SwiftUI.Animation = .easeInOut(duration: 0.2)
        static let smooth: SwiftUI.Animation = .easeInOut(duration: 0.3)
        static let bounce: SwiftUI.Animation = .interpolatingSpring(stiffness: 300, damping: 20)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        Theme.Card.style(self)
    }
    
    func primaryCardStyle() -> some View {
        Theme.Card.yellowHeaderStyle(self)
    }
    
    func figmaButtonStyle() -> some View {
        self
            .frame(minHeight: Theme.Size.button)
            .background(Theme.Colors.primary)
            .foregroundColor(Theme.Colors.text)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Theme.Colors.cardBorder, lineWidth: 1)
            )
    }
}
