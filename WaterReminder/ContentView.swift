import SwiftUI
import SwiftData
import UserNotifications
import SwiftUIGIF

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var waterModel = WaterModel()
    
    @State private var water: Int = 0
    @State private var showPopup = false
    @State private var selectedAmount: Int = -50
    @State private var showResetPopup = false
    
    var body: some View {
        VStack {
            // Header with GIF and daily count
            HStack {
                if let settings = waterModel.appSettings, settings.dailyCount > 3 {
                    GIFImage(name: "fire")
                        .frame(width: 30, height: 100)
                }
                if let settings = waterModel.appSettings {
                    Text("\(settings.dailyCount)")
                }
            }
            .frame(height: 5)
            
            // Water progress view
            HStack {
                FilledDrop(progress: calculateTotalProgress())
                VStack {
                    ProgressView(value: calculateTotalProgress(), total: 4000) {
                        if calculateTotalProgress() < 4000 {
                            Text("Jeszcze \(Int(4000 - calculateTotalProgress())) ml")
                                .foregroundStyle(calculateTotalProgress() < 2000 ? .red : (calculateTotalProgress() < 4000 || calculateTotalProgress() > 1500) ? .yellow : .white)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .font(.custom("FONT_NAME", size: 22))
                                .fontWeight(.bold)
                        } else {
                            Text("Wypiłeś już \(Int(calculateTotalProgress())) ml")
                                .foregroundStyle(calculateTotalProgress() >= 4000 ? .green : .white)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .font(.custom("FONT_NAME", size: 22))
                                .fontWeight(.bold)
                        }
                    }
                    .frame(width: 250, height: 20)
                    
                    Text("Powinieneś mieć: \(calculateHourWater())")
                        .foregroundStyle(calculateHourWater() - Int(calculateTotalProgress()) > 1000 ? .red : (calculateHourWater() - Int(calculateTotalProgress()) > 0 ? .yellow : .green))
                        .font(.custom("FONT_NAME", size: 10))
                }
            }
            .padding()
            
            // Water input controls
            HStack {
                Picker(selection: $water, label: Text("Ile wypiłeś?")) {
                    ForEach(Array(stride(from: 50, through: 1000, by: 50)), id: \.self) { value in
                        Text("\(value) ml")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                Button("Dodaj") {
                    waterModel.addWaterProgress(Double(water))
                    water = 0
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            
            // Quick action buttons
            HStack {
                VStack {
                    Button("Wypito 250 ml") {
                        waterModel.addWaterProgress(250)
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Wypito 500 ml") {
                        waterModel.addWaterProgress(500)
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                VStack {
                    if let settings = waterModel.appSettings, settings.boilerWater > 249 {
                        Button("Bojler 250 ml") {
                            waterModel.addWaterProgress(250)
                            waterModel.updateBoilerWater(by: 250)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        if let settings = waterModel.appSettings {
                            Text("Stan bojlera: \(settings.boilerWater)")
                                .font(.custom("FONT_NAME", size: 10))
                        }
                    } else {
                        Text("Uzupełnij bojler")
                        
                        Button("Uzupełniony!") {
                            waterModel.appSettings?.boilerWater = 2000
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            
            // History view
            Text("Historia z ostatnich dni")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(waterModel.waterProgresses.sorted(by: { $0.date > $1.date })) { entry in
                        HStack {
                            Text("\(entry.date.formatted(date: .abbreviated, time: .omitted))")
                            Spacer()
                            Text("\(Int(entry.progress)) ml")
                                .foregroundStyle(entry.progress < 2500 ? .red : (entry.progress < 4000 ? .yellow : .green))
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 200)
            
            Spacer()
            
            // Undo button
            Button("Jednak nie wypiłem") {
                selectedAmount = -50
                showPopup = true
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .onAppear {
            requestNotificationPermission()
            createNotificationActions()
            scheduleDailyNotifications(withAmount: 250)
        }
    }
    
    private func calculateTotalProgress() -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        if let existingEntry = waterModel.waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return existingEntry.progress
        }
        return 0
    }
    
    private func calculateHourWater() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let startHour = 10
        let startMinute = 0
        
        let totalMinutesSinceStart = (currentHour - startHour) * 60 + (currentMinute - startMinute)
        let intervals = Int(ceil(Double(totalMinutesSinceStart) / 50.0))
        return 250 * intervals
    }
    
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    private func createNotificationActions() {
        let drinkAction = UNNotificationAction(identifier: "DRINK_ACTION", title: "Wypito", options: [])
        let delayAction = UNNotificationAction(identifier: "DELAY_ACTION", title: "Nie mogę", options: [])
        let category = UNNotificationCategory(identifier: "WATER_REMINDER", actions: [drinkAction, delayAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    private func scheduleDailyNotifications(withAmount amount: Int) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Wypij szklankę wody"
        content.body = "Do wypicia: \(amount) ml"
        content.sound = .default
        content.categoryIdentifier = "WATER_REMINDER"
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: Date())
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        for hour in 10...22 {
            dateComponents.hour = hour
            for minute in stride(from: 0, to: 60, by: 50) {
                dateComponents.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                center.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

struct FilledDrop: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Image(systemName: "drop.fill")
                .resizable()
                .frame(width: 50, height: 70)
                .foregroundColor(.gray.opacity(0.5))
            
            Image(systemName: "drop.fill")
                .resizable()
                .frame(width: 50, height: 70)
                .foregroundColor(.blue)
                .mask(
                    Rectangle()
                        .frame(height: max(0, 70 * progress / 4000))
                        .offset(y: (70 - (70 * progress / 4000)) / 2)
                )
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WaterProgress.self)
}
