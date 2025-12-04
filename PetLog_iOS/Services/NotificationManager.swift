import Foundation
import UIKit
import UserNotifications
import Combine

// MARK: - Notification Manager
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    // MARK: - Properties
    @Published var pushToken: String? {
        didSet {
            if let token = pushToken {
                UserDefaults.standard.set(token, forKey: "pushToken")
            }
        }
    }
    
    @Published var isNotificationEnabled: Bool = false
    
    private override init() {
        super.init()
        loadSavedPushToken()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Public Methods
    
    /// Compute next reminder date from last time + cycle hours (rolls forward to a future date)
    private func nextOccurrence(from last: Date, cycleHours: Int, now: Date = Date()) -> Date {
        let interval = TimeInterval(cycleHours * 3600)
        // Start from the first scheduled time after the last action
        var next = last.addingTimeInterval(interval)
        if next > now { return next }
        // If we're already past, roll forward by whole intervals
        let delta = now.timeIntervalSince(last)
        let steps = Int(floor(delta / interval)) + 1
        return last.addingTimeInterval(TimeInterval(steps) * interval)
    }
    
    enum ReminderType: String { case feeding = "FEEDING_REMINDER"; case watering = "WATERING_REMINDER" }
    
    /// Schedule a specific reminder using the user's preferred naming `remindNotificationAt`.
    /// - Parameters:
    ///   - type: Reminder type (feeding or watering)
    ///   - lastTime: The last recorded time (UTC already parsed into Date)
    ///   - cycleHours: Interval in hours after which to remind
    ///   - checkerName: Optional name to personalize the body
    func scheduleRemindNotificationAt(for type: ReminderType, lastTime: Date, cycleHours: Int, checkerName: String? = nil) {
        let triggerDate = nextOccurrence(from: lastTime, cycleHours: cycleHours)
        let title: String
        let body: String
        switch type {
        case .feeding:
            title = "밥 먹을 시간이에요!"
            body = "\(checkerName ?? "")님, 밥을 줄 시간입니다.".trimmingCharacters(in: .whitespaces)
        case .watering:
            title = "물을 교체할 시간이에요!"
            body = "\(checkerName ?? "")님, 물을 교체하세요.".trimmingCharacters(in: .whitespaces)
        }
        scheduleReminder(title: title, body: body, triggerDate: triggerDate, identifier: type.rawValue, action: type.rawValue)
    }
    
    /// Schedule reminders for dashboard data (feeding + watering)
    func scheduleActivityReminders(feeding: Feeding, watering: Watering) {
        // Clear existing ones to avoid duplicates
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            ReminderType.feeding.rawValue,
            ReminderType.watering.rawValue
        ])
        
        scheduleRemindNotificationAt(for: .feeding, lastTime: feeding.lastFeedingTime, cycleHours: feeding.feedingCycle, checkerName: feeding.lastCheckerName)
        scheduleRemindNotificationAt(for: .watering, lastTime: watering.lastWateringTime, cycleHours: watering.wateringCycle, checkerName: watering.lastCheckerName)
        
        print("🔔 Scheduled reminders:")
        print("   Feeding -> next at: \(nextOccurrence(from: feeding.lastFeedingTime, cycleHours: feeding.feedingCycle))")
        print("   Watering -> next at: \(nextOccurrence(from: watering.lastWateringTime, cycleHours: watering.wateringCycle))")
    }
    
    /// Schedule a single local notification
    private func scheduleReminder(
        title: String,
        body: String,
        triggerDate: Date,
        identifier: String,
        action: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["action": action, "remindNotificationAt": ISO8601DateFormatter().string(from: triggerDate)]
        
        // Use calendar trigger for an absolute fire date in local time
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule \(identifier): \(error.localizedDescription)")
            } else {
                print("✅ \(identifier) scheduled at: \(triggerDate)")
            }
        }
    }
    
    /// Request notification permission from user
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationEnabled = granted
                if granted {
                    print("✅ Notification permission granted")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown")")
                }
            }
        }
    }
    
    /// Handle received device token
    func handleDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.pushToken = token
        print("🔔 Device token received: \(token)")
        
        // Save to backend
        Task {
            await savePushTokenToBackend(token)
        }
    }
    
    /// Handle registration failure
    func handleRegistrationFailure(_ error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("📬 Received notification in foreground: \(userInfo)")
        
        // Show notification even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
        
        handleNotificationTapped(userInfo: userInfo)
    }
    
    /// Handle notification when user taps it
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("📭 Notification tapped: \(userInfo)")
        
        handleNotificationTapped(userInfo: userInfo)
        completionHandler()
    }
    
    // MARK: - Private Methods
    
    private func loadSavedPushToken() {
        if let saved = UserDefaults.standard.string(forKey: "pushToken") {
            self.pushToken = saved
            print("📌 Loaded saved push token: \(saved.prefix(20))...")
        }
    }
    
    private func handleNotificationTapped(userInfo: [AnyHashable: Any]) {
        // Parse notification data
        if let title = userInfo["title"] as? String,
           let body = userInfo["body"] as? String {
            print("📢 Notification - Title: \(title), Body: \(body)")
            
            // Handle specific actions based on notification type
            if let action = userInfo["action"] as? String {
                handleNotificationAction(action, userInfo: userInfo)
            }
        }
    }
    
    private func handleNotificationAction(_ action: String, userInfo: [AnyHashable: Any]) {
        switch action {
        case "FEEDING_REMINDER":
            print("🍽️ Feeding reminder notification tapped")
            // Navigate to feeding view
        case "WATERING_REMINDER":
            print("💧 Watering reminder notification tapped")
            // Navigate to watering view
        case "POOP_REMINDER":
            print("🚽 Poop reminder notification tapped")
            // Navigate to poop view
        default:
            print("📌 Unknown action: \(action)")
        }
    }
    
    private func savePushTokenToBackend(_ token: String) async {
        do {
            try await PetLogAPIService.shared.savePushToken(token: token)
            print("✅ Push token saved to backend")
        } catch {
            print("❌ Failed to save push token: \(error)")
        }
    }
}
