import SwiftUI
import SwiftData
import UserNotifications

@main
struct WaterReminderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: WaterProgress.self)
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
                scheduleNotification(withAmount: amount + 250)
            }
        }
        
        completionHandler()
    }
}
func scheduleNotification(withAmount amount: Int) {
    let content = UNMutableNotificationContent()
    content.title = "Pora na wodę!"
    content.body = "Wypij \(amount) ml wody"
    content.sound = UNNotificationSound.default
    content.userInfo = ["amount": amount] // Przekazujemy ilość wody
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 900, repeats: false) // 15 min
    
    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Błąd powiadomienia: \(error.localizedDescription)")
        }
    }
}

