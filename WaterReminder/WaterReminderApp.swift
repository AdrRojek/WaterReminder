import SwiftUI
import SwiftData

@main
struct WaterReminderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: WaterProgress.self) // Dodaj kontener modelu
        }
    }
}
