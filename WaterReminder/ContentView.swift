import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    init() {
            requestNotificationPermission()
        }
    @Environment(\.modelContext) private var modelContext
    @Query private var waterProgresses: [WaterProgress]
    
    @State private var water: Int = 0
    @State private var showPopup = false
    @State private var selectedAmount: Int = -50
    @State private var showResetPopup = false
    
    var body: some View {
        
        VStack {
            HStack {
                
                Image(systemName: "drop.fill")
                    .resizable()
                    .frame(width: 50, height: 70)
                    .foregroundColor(.blue)
                
                ProgressView(value: calculateTotalProgress(), total: 4000) {
                    if calculateTotalProgress() < 4000 {
                        Text("Jeszcze \(Int(4000 - calculateTotalProgress())) ml")
                        
                    } else {
                        Text("Wypiłeś już \(Int(calculateTotalProgress())) ml")
                    }
                }
                .frame(width: 200, height: 20)
            }
            .padding()
            
            HStack {
                Picker(selection: $water, label: Text("Ile wypiłeś?")) {
                    ForEach(Array(stride(from: 50, through: 1000, by: 50)), id: \.self) { value in
                        Text("\(value) ml")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                Button("Dodaj") {
                    addOrUpdateWaterProgress(Double(water))
                    water = 0
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            
            HStack {
                Button("Wypito 250 ml") {
                    addOrUpdateWaterProgress(250)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Wypito 500 ml") {
                    addOrUpdateWaterProgress(500)
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            
            Text("Historia z ostatnich dni")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(waterProgresses.sorted(by: { $0.date > $1.date })) { entry in
                        HStack {
                            Text("\(entry.date.formatted(date: .abbreviated, time: .shortened))")
                            Spacer()
                            Text("\(Int(entry.progress)) ml")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 300)
            
            Spacer()
            
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
        .onAppear{
            requestNotificationPermission()
            createNotificationActions()
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ADD_WATER"), object: nil, queue: .main) { notification in
                            if let amount = notification.userInfo?["amount"] as? Double {
                                addOrUpdateWaterProgress(amount)
                            }
                        }
        }
        .sheet(isPresented: $showPopup) {
            VStack(alignment: .leading){
                Button("Cofnij"){
                    showPopup = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            VStack {
                Text("Ile chcesz odjąć?")
                    .padding()
                    .font(.system(size: 20))
                    .fontWeight(.bold)

                Picker("Ile chcesz odjąć?", selection: $selectedAmount) {
                    ForEach(Array(stride(from: 0, through: 1000, by: 50)), id: \.self) { value in
                        Text("\((value * -1)) ml")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 150)
                
                Button("Zatwierdź") {
                    subtractWaterProgress(Double(selectedAmount))
                    showPopup = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
                
                Button("Resetuj cały dzień"){
                    showResetPopup = true
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                
            }
            .padding()
            .presentationDetents([.height(500)])
            .presentationDragIndicator(.visible)
        }
        
        
        .popover(isPresented: $showResetPopup){
            VStack(spacing: 50){
                Text("Czy na pewno chcesz zresetować?")
                    .fontWeight(.bold)
                    .font(.system(size: 20))
            
            
            HStack(spacing: 30){
                
                Button("Nie"){
                    showResetPopup = false
                    showPopup = true
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                
                Button("Tak"){
                    resetWater()
                    showResetPopup = false
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                
            }
            }
            .presentationDetents([.height(500)])
            .presentationDragIndicator(.visible)
        }
        .padding()
        
        
    }
    
    private func addOrUpdateWaterProgress(_ amount: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existingEntry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existingEntry.progress += amount
        } else {
            let newEntry = WaterProgress(progress: amount, maxProgress: 4000)
            modelContext.insert(newEntry)
        }
    }
    
    private func subtractWaterProgress(_ amount: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existingEntry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existingEntry.progress -= amount
            if existingEntry.progress < 0 {
                existingEntry.progress = 0
            }
        }
    }
    
    private func resetWater(){
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existingEntry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            if existingEntry.progress != 0 {
                existingEntry.progress = 0
            }
        }
    }
    
    private func calculateTotalProgress() -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existingEntry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            if existingEntry.progress != 0 {
                return existingEntry.progress
            }else {
                return 0
            }
        }
        return 0
    }
    
    private func printDatabaseContents() {
        for entry in waterProgresses {
            print("Data: \(entry.date), Ilość: \(entry.progress) ml")
        }
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        center.requestAuthorization(options: options) { granted, error in
            if granted {
                print("Uprawnienia do powiadomień zostały przyznane.")
            } else {
                print("Uprawnienia do powiadomień nie zostały przyznane.")
            }
            
            if let error = error {
                print("Błąd podczas żądania uprawnień: \(error.localizedDescription)")
            }
        }
    }
    
    func createNotificationActions() {
        let drinkAction = UNNotificationAction(
            identifier: "DRINK_ACTION",
            title: "Wypito",
            options: []
        )
        
        let delayAction = UNNotificationAction(
            identifier: "DELAY_ACTION",
            title: "Nie mogę",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "WATER_REMINDER",
            actions: [drinkAction, delayAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    private func initializeWaterProgress() {
        let today = Calendar.current.startOfDay(for: Date())

        if let existingEntry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            // Jeśli już istnieje wpis, nic nie zmieniamy
        } else {
            let newEntry = WaterProgress(progress: 0, maxProgress: 4000, startTime: Date())
            modelContext.insert(newEntry)
            scheduleNotifications(for: newEntry.startTime)
        }
    }
    
    private func calculateIntervals(startTime: Date) -> [Date] {
        let endHour = 21
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        
        guard let startHour = startComponents.hour else { return [] }
        
        let availableHours = endHour - startHour
        let waterToDrink = 4000 - 500 - 500 // 500 ml rano i wieczorem
        let glassSize = 250
        let intervals = (waterToDrink / glassSize) // Ilość szklanek w ciągu dnia

        let intervalDuration = availableHours / intervals // Co ile godzin powiadomienie
        var notificationTimes: [Date] = []
        
        for i in 0..<intervals {
            if let notifyTime = calendar.date(byAdding: .hour, value: i * intervalDuration, to: startTime) {
                notificationTimes.append(notifyTime)
            }
        }

        return notificationTimes
    }

    

    func scheduleNotifications(for startTime: Date) {
        let notificationTimes = calculateIntervals(startTime: startTime)
        
        for time in notificationTimes {
            let content = UNMutableNotificationContent()
            content.title = "Pora na wodę!"
            content.body = "Wypij 250 ml"
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = "WATER_REMINDER"

            let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Błąd: \(error.localizedDescription)")
                }
            }
        }
    }

}



#Preview {
    ContentView()
        .modelContainer(for: WaterProgress.self)
}
