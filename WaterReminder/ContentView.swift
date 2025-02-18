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
                Button("Wyślij powiadomienie") {
                    scheduleNotification(withAmount: 250)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                FilledDrop(progress: calculateTotalProgress())
                
                ProgressView(value: calculateTotalProgress(), total: 4000) {
                    if calculateTotalProgress() < 4000 {
                        Text("Jeszcze \(Int(4000 - calculateTotalProgress())) ml")
                            .foregroundStyle(calculateTotalProgress()<2000 ? .red :
                                            (calculateTotalProgress()<4000 || calculateTotalProgress()>1500) ? .yellow : .white)
                    } else {
                        Text("Wypiłeś już \(Int(calculateTotalProgress())) ml")
                            .foregroundStyle(calculateTotalProgress() >= 4000 ? .green : .white)
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
    
}

func scheduleNotification(withAmount amount: Int) {
    let content = UNMutableNotificationContent()
    content.title = "Wypij szklankę wody"
    content.body = "Do wypicia: \(amount) ml"
    content.sound = UNNotificationSound.default
    content.categoryIdentifier = "WATER_REMINDER"
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false) 
    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Błąd podczas planowania powiadomienia: \(error.localizedDescription)")
        } else {
            print("Powiadomienie zaplanowane z ilością \(amount) ml")
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
