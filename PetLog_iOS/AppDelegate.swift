import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // MARK: - Initialize Notification Manager
        let notificationManager = NotificationManager.shared
        
        // Request notification permission
        notificationManager.requestNotificationPermission()
        
        // Handle notification from launch
        if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            handleRemoteNotification(notification)
        }
        
        return true
    }
    
    // MARK: - Remote Notification Handling
    
    /// Handle device token registration
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.handleDeviceToken(deviceToken)
    }
    
    /// Handle device token registration failure
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationManager.shared.handleRegistrationFailure(error)
    }
    
    /// Handle remote notification when app is not running or in background
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📬 Received remote notification in background")
        handleRemoteNotification(userInfo)
        completionHandler(.newData)
    }
    
    // MARK: - Scene Configuration
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
    
    // MARK: - Private Methods
    
    private func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        print("📢 Processing remote notification: \(userInfo)")
        // Notification processing is handled in NotificationManager
    }
}
