import SwiftUI
import SwiftData
import UserNotifications
import SwiftUIGIF

struct ContentView: View {
    init() {
        requestNotificationPermission()
        initializeBoilerModel()
    }
    @Environment(\.modelContext) private var modelContext
    @Query private var waterProgresses: [WaterProgress]
    @Query private var boilerModels: [BoilerModel]
    @Query private var dailyCountModels: [DailyCountModel]
    
    @State private var water: Int = 0
    @State private var showPopup = false
    @State private var selectedAmount: Int = -50
    @State private var showResetPopup = false
    @State private var boilerWater = 2000
    @State private var dailyCount = 0
    
    var body: some View {
        
        VStack {
            HStack {
                if calculateStreak() > 3 {
                    GIFImage(name: "fire")
                        .frame(width: 30, height: 100)
                }
                Text("\(calculateStreak())")
            }
            .frame(height: 5)
            HStack {
                
                FilledDrop(progress: calculateTotalProgress())
                VStack{
                    ProgressView(value: calculateTotalProgress(), total: 4000) {
                        if calculateTotalProgress() < 4000 {
                            Text("Jeszcze \(Int(4000 - calculateTotalProgress())) ml")
                                .foregroundStyle(calculateTotalProgress()<2000 ? .red :
                                                    (calculateTotalProgress()<4000 || calculateTotalProgress()>1500) ? .yellow : .white)
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
                        .foregroundStyle(calculateHourWater() - Int(calculateTotalProgress()) > 1000  ? .red : (calculateHourWater() - Int(calculateTotalProgress()) > 0  ? .yellow : .green)
                        )
                        .font(.custom("FONT_NAME", size: 10))
                }
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
                    updateDailyCount()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            
            HStack {
                VStack{
                    Button("Wypito 250 ml") {
                        addOrUpdateWaterProgress(250)
                        updateDailyCount()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Wypito 500 ml") {
                        addOrUpdateWaterProgress(500)
                        updateDailyCount()
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                VStack{
                    if let boilerModel = boilerModels.first, boilerModel.amount > 249 {
                        Button("Bojler 250 ml") {
                            print("Button 'Bojler 250 ml' clicked")
                            updateBoiler(-250)
                            addOrUpdateWaterProgress(250)
                            updateDailyCount()
                            print("Boiler water updated to \(boilerModel.amount) ml")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Text("Stan bojlera: \(boilerModel.amount) ml")
                            .font(.custom("FONT_NAME", size: 10))
                    } else {
                        Text("Uzupełnij bojler")
                        
                        Button("Uzupełniony!") {
                            updateBoiler(2000)
                            print("Boiler water reset to 2000 ml")
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
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
            initializeBoilerModel()
            print("Boiler models count: \(boilerModels.count)")
            
            scheduleAllWeeklyNotifications()
            
            if boilerModels.isEmpty {
                let initialBoiler = BoilerModel(amount: 2000)
                modelContext.insert(initialBoiler)
            }
            
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
                HStack{
                    Button("Woda") {
                        subtractWaterProgress(Double(selectedAmount))
                        showPopup = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    if let boilerModel = boilerModels.first, boilerModel.amount != 2000 {
                        Button("Boiler") {
                            let newAmount = boilerModel.amount + selectedAmount
                            if newAmount <= 2000 && newAmount >= 0 {
                                subtractWaterProgress(Double(selectedAmount))
                                boilerModel.amount = newAmount
                                do {
                                    try modelContext.save()
                                    print("Boiler water updated to \(boilerModel.amount) ml")
                                } catch {
                                    print("Failed to update boiler model: \(error.localizedDescription)")
                                }
                            }else if(newAmount > 2000){
                                subtractWaterProgress(Double(2000-boilerModel.amount))
                                boilerModel.amount = 2000
                                do {
                                    try modelContext.save()
                                    print("Boiler water updated to \(boilerModel.amount) ml")
                                } catch {
                                    print("Failed to update boiler model: \(error.localizedDescription)")
                                }
                            }
                            
                            showPopup = false
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
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
        updateDailyCountModel()
    }
    
    func updateDailyCount() {
        let sortedEntries = waterProgresses.sorted(by: { $0.date > $1.date })
        
        var count = 0
        var previousDate: Date?
        
        for entry in sortedEntries {
            if entry.progress >= 4000 {
                if let prevDate = previousDate, Calendar.current.isDate(prevDate, inSameDayAs: entry.date) == false {
                    count += 1
                } else if previousDate == nil {
                    count += 1
                }
            } else {
                break
            }
            previousDate = entry.date
        }
        
        dailyCount = count
    }
    
    private func updateDailyCountModel() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existingEntry = dailyCountModels.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existingEntry.done = calculateTotalProgress() >= 4000
        } else {
            let newEntry = DailyCountModel(
                dailyCount: 0,
                date: today,
                done: calculateTotalProgress() >= 4000
            )
            modelContext.insert(newEntry)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Błąd zapisu: \(error.localizedDescription)")
        }
    }
    
    private func calculateStreak() -> Int {
        let sortedEntries = dailyCountModels.sorted(by: { $0.date > $1.date })
        
        var streak = 0
        let today = Calendar.current.startOfDay(for: Date())
        var expectedDate = today
        
        if let todayEntry = sortedEntries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }), todayEntry.done {
            streak += 1
            expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate)!
        } else {
            expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate)!
        }
        
        for entry in sortedEntries {
            let entryDate = Calendar.current.startOfDay(for: entry.date)
            
            guard entryDate < today else { continue }
            
            while entryDate < expectedDate {
                return streak
            }
            
            if Calendar.current.isDate(entryDate, inSameDayAs: expectedDate), entry.done {
                streak += 1
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if entryDate == expectedDate {
                return streak
            }
        }
        
        return streak
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
    
    private func updateBoiler(_ amountChange: Int) {
        if let boilerModel = boilerModels.first {
            let newAmount = boilerModel.amount + amountChange
            if newAmount >= 0 && newAmount <= 2000 {
                boilerModel.amount = newAmount
                do {
                    try modelContext.save()
                    print("Boiler updated to \(boilerModel.amount) ml")
                } catch {
                    print("Failed to save boiler model: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func initializeBoilerModel() {
        if boilerModels.isEmpty {
            let initialBoiler = BoilerModel(amount: 2000)
            modelContext.insert(initialBoiler)
            do {
                try modelContext.save()
                print("Initial BoilerModel created successfully")
            } catch {
                print("Failed to initialize BoilerModel: \(error.localizedDescription)")
            }
        }
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
    
    func scheduleDailyNotifications(withAmount amount: Int) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Wypij szklankę wody"
        content.body = "Do wypicia: \(amount) ml | Do tej pory: \(Int(calculateTotalProgress())) ml"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "WATER_REMINDER"
        
        if let imageURL = Bundle.main.url(forResource: "water", withExtension: "png"),
           let attachment = try? UNNotificationAttachment(identifier: "waterIcon", url: imageURL, options: nil) {
            content.attachments = [attachment]
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        while dateComponents.hour! <= 22 {
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Błąd podczas dodawania powiadomienia: \(error.localizedDescription)")
                } else {
                    print("Powiadomienie zaplanowane na \(dateComponents.hour!):\(String(format: "%02d", dateComponents.minute!))")
                }
            }
            
            dateComponents.minute! += 50
            if dateComponents.minute! >= 60 {
                dateComponents.hour! += 1
                dateComponents.minute! -= 60
            }
            
            if dateComponents.hour! > 22 {
                break
            }
        }
    }
    
    func calculateHourWater() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let startHour = 10
        let startMinute = 0
        
        let totalMinutesSinceStart = (currentHour - startHour) * 60 + (currentMinute - startMinute)
        
        let intervals = Int(ceil(Double(totalMinutesSinceStart) / 50.0))
        
        let recommendedWater = 250 * intervals
        
        return recommendedWater
    }
    
    
    func scheduleWeeklyMondayNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let times = [
            (10, 0),
            (10, 50),
            (11, 40),
            (12, 30),
            (13, 20),
            (14, 10),
            (15, 0),
            (15, 50),
            (16, 40),
            (17, 30),
            (18, 20),
            (19, 10),
            (20, 0),
            (20, 50),
            (21, 40),
            (22, 00)
        ]
        
        for (hour, minute) in times {
            let content = UNMutableNotificationContent()
            content.title = "Wypij szklankę wody"
            content.body = "Do wypicia: 250 ml"
            content.sound = .default
            content.categoryIdentifier = "WATER_REMINDER"
            
            var dateComponents = DateComponents()
            dateComponents.weekday = 2
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "MONDAY_\(hour)_\(minute)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Błąd dla \(hour):\(minute): \(error.localizedDescription)")
                } else {
                    print("Zaplanowano na poniedziałek \(hour):\(String(format: "%02d", minute))")
                }
            }
        }
    }
    func scheduleWeeklyTuesdayNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let times = [
            (10, 0),
            (10, 50),
            (11, 40),
            (12, 30),
            (13, 20),
            (14, 10),
            (15, 0),
            (15, 50),
            (16, 40),
            (17, 30),
            (18, 20),
            (19, 10),
            (20, 0),
            (20, 50),
            (21, 40),
            (22, 00)
        ]
        
        for (hour, minute) in times {
            let content = UNMutableNotificationContent()
            content.title = "Wypij szklankę wody"
            content.body = "Do wypicia: 250 ml | Do tej pory: \(Int(calculateTotalProgress())) ml"
            content.sound = .default
            content.categoryIdentifier = "WATER_REMINDER"
            
            var dateComponents = DateComponents()
            dateComponents.weekday = 3
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "TUESDAY_\(hour)_\(minute)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Błąd dla \(hour):\(minute): \(error.localizedDescription)")
                } else {
                    print("Zaplanowano na Wtorek \(hour):\(String(format: "%02d", minute))")
                }
            }
        }
    }
    func scheduleWeeklyWednesdayNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let times = [
            (10, 0),
            (10, 50),
            (11, 40),
            (12, 30),
            (13, 20),
            (14, 10),
            (15, 0),
            (15, 50),
            (16, 40),
            (17, 30),
            (18, 20),
            (19, 10),
            (20, 0),
            (20, 50),
            (21, 40),
            (22, 00)
        ]
        
        for (hour, minute) in times {
            let content = UNMutableNotificationContent()
            content.title = "Wypij szklankę wody"
            content.body = "Do wypicia: 250 ml | Do tej pory: \(Int(calculateTotalProgress())) ml"
            content.sound = .default
            content.categoryIdentifier = "WATER_REMINDER"
            
            var dateComponents = DateComponents()
            dateComponents.weekday = 4
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "WEDNESDAY_\(hour)_\(minute)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Błąd dla \(hour):\(minute): \(error.localizedDescription)")
                } else {
                    print("Zaplanowano na Środe \(hour):\(String(format: "%02d", minute))")
                }
            }
        }
    }
    func scheduleWeeklyThursdayNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let times = [
            (10, 0),
            (10, 50),
            (11, 40),
            (12, 30),
            (13, 20),
            (14, 10),
            (15, 0),
            (15, 50),
            (16, 40),
            (17, 30),
            (18, 20),
            (19, 10),
            (20, 0),
            (20, 50),
            (21, 40),
            (22, 00)
        ]
        
        for (hour, minute) in times {
            let content = UNMutableNotificationContent()
            content.title = "Wypij szklankę wody"
            content.body = "Do wypicia: 250 ml | Do tej pory: \(Int(calculateTotalProgress())) ml"
            content.sound = .default
            content.categoryIdentifier = "WATER_REMINDER"
            
            var dateComponents = DateComponents()
            dateComponents.weekday = 5
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "THURSDAY_\(hour)_\(minute)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Błąd dla \(hour):\(minute): \(error.localizedDescription)")
                } else {
                    print("Zaplanowano na Czwartek \(hour):\(String(format: "%02d", minute))")
                }
            }
        }
    }
    func scheduleWeeklyFridayNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let times = [
            (10, 0),
            (10, 50),
            (11, 40),
            (12, 30),
            (13, 20),
            (14, 10),
            (15, 0),
            (15, 50),
            (16, 40),
            (17, 30),
            (18, 20),
            (19, 10),
            (20, 0),
            (20, 50),
            (21, 40),
            (22, 00)
        ]
        
        for (hour, minute) in times {
            let content = UNMutableNotificationContent()
            content.title = "Wypij szklankę wody"
            content.body = "Do wypicia: 250 ml | Do tej pory: \(Int(calculateTotalProgress())) ml"
            content.sound = .default
            content.categoryIdentifier = "WATER_REMINDER"
            
            var dateComponents = DateComponents()
            dateComponents.weekday = 5
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "FRIDAY_\(hour)_\(minute)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Błąd dla \(hour):\(minute): \(error.localizedDescription)")
                } else {
                    print("Zaplanowano na Piątek \(hour):\(String(format: "%02d", minute))")
                }
            }
        }
    }
    func scheduleWeeklySaturdayNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let times = [
            (10, 0),
            (10, 50),
            (11, 40),
            (12, 30),
            (13, 20),
            (14, 10),
            (15, 0),
            (15, 50),
            (16, 40),
            (17, 30),
            (18, 20),
            (19, 10),
            (20, 0),
            (20, 50),
            (21, 40),
            (22, 00)
        ]
        
        for (hour, minute) in times {
            let content = UNMutableNotificationContent()
            content.title = "Wypij szklankę wody"
            content.body = "Do wypicia: 250 ml | Do tej pory: \(Int(calculateTotalProgress())) ml"
            content.sound = .default
            content.categoryIdentifier = "WATER_REMINDER"
            
            var dateComponents = DateComponents()
            dateComponents.weekday = 7
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "SATURDAY_\(hour)_\(minute)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Błąd dla \(hour):\(minute): \(error.localizedDescription)")
                } else {
                    print("Zaplanowano na Sobote \(hour):\(String(format: "%02d", minute))")
                }
            }
        }
    }
    func scheduleWeeklySundayNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let times = [
            (10, 0),
            (10, 50),
            (11, 40),
            (12, 30),
            (13, 20),
            (14, 10),
            (15, 0),
            (15, 50),
            (16, 40),
            (17, 30),
            (18, 20),
            (19, 10),
            (20, 0),
            (20, 50),
            (21, 40),
            (22, 00)
        ]
        
        for (hour, minute) in times {
            let content = UNMutableNotificationContent()
            content.title = "Wypij szklankę wody"
            content.body = "Do wypicia: 250 ml | Do tej pory: \(Int(calculateTotalProgress())) ml"
            content.sound = .default
            content.categoryIdentifier = "WATER_REMINDER"
            
            var dateComponents = DateComponents()
            dateComponents.weekday = 1
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "SUNDAY_\(hour)_\(minute)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Błąd dla \(hour):\(minute): \(error.localizedDescription)")
                } else {
                    print("Zaplanowano na Niedziele \(hour):\(String(format: "%02d", minute))")
                }
            }
        }
    }
    
    func scheduleAllWeeklyNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        scheduleWeeklyMondayNotifications()
        scheduleWeeklyTuesdayNotifications()
        scheduleWeeklyWednesdayNotifications()
        scheduleWeeklyThursdayNotifications()
        scheduleWeeklyFridayNotifications()
        scheduleWeeklySaturdayNotifications()
        scheduleWeeklySundayNotifications()
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
        .modelContainer(for: [WaterProgress.self, BoilerModel.self, DailyCountModel.self])
}
