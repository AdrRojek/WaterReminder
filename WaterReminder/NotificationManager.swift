import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func scheduleNotification(at date: Date, withAmount amount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Wypij szklankę wody"
        content.body = "Do wypicia: \(amount) ml"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "WATER_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: date.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Błąd podczas planowania powiadomienia: \(error.localizedDescription)")
            } else {
                print("Powiadomienie zaplanowane na \(date) z ilością \(amount) ml")
            }
        }
    }
}
