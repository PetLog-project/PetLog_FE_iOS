import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Handle notification that opened the app
        for userActivity in connectionOptions.userActivities {
            if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
                handleNotificationUserActivity(userActivity)
            }
        }
        
        // Let PetLog_iOSApp handle the root view setup via @main
        // Do not set window.rootViewController - SwiftUI manages it
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Update badge count when app becomes active
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - Notification Handling
    
    private func handleNotificationUserActivity(_ userActivity: NSUserActivity) {
        // Handle notification deep linking if needed
        print("📭 User activity from notification: \(userActivity)")
    }
}
