import SwiftUI
import SwiftData
import UserNotifications

@main
struct WaterReminderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [WaterProgress.self, BoilerModel.self, DailyCountModel.self])
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if response.actionIdentifier == "DRINK_ACTION" {
            NotificationCenter.default.post(name: NSNotification.Name("ADD_WATER"), object: nil, userInfo: ["amount": 250])
        } else if response.actionIdentifier == "DELAY_ACTION" {
            if let amount = userInfo["amount"] as? Int {
            }
        }
        
        completionHandler()
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
