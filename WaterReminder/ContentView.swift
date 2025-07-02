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
    @State private var showPastDayPopup = false
    @State private var selectedPastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    @State private var pastDayAmount = 250
    @State private var isPastDayBoiler = false
    @State private var isYesterdaySelected = false
    @State private var currentTime = Date()
    @State private var updateTimer: Timer?
    
    var body: some View {
        NavigationView {
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
                    
                    FilledDrop(progress: calculateDynamicProgress())
                    VStack{
                        ProgressView(value: calculateDynamicProgress(), total: 4000) {
                            if calculateDynamicProgress() < 4000 {
                                Text("Jeszcze \(Int(4000 - calculateDynamicProgress())) ml")
                                    .foregroundStyle(calculateDynamicProgress()<2000 ? .red :
                                                        (calculateDynamicProgress()<4000 || calculateDynamicProgress()>1500) ? .yellow : .white)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.custom("FONT_NAME", size: 22))
                                    .fontWeight(.bold)
                            } else {
                                Text("Wypiłeś już \(Int(calculateDynamicProgress())) ml")
                                    .foregroundStyle(calculateDynamicProgress() >= 4000 ? .green : .white)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.custom("FONT_NAME", size: 22))
                                    .fontWeight(.bold)
                            }
                            
                        }
                        .frame(width: 250, height: 20)
                        
                        Text("Powinieneś mieć: \(calculateHourWater())")
                            .foregroundStyle(calculateHourWater() - Int(calculateDynamicProgress()) > 1000  ? .red : (calculateHourWater() - Int(calculateDynamicProgress()) > 0  ? .yellow : .green)
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
                        if let boilerModel = boilerModels.first {
                            // Debug log
                            let _ = print("DEBUG: Boiler amount: \(boilerModel.amount) ml")
                            
                            if boilerModel.amount > 249 {
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
                                if entry.kreatyna {
                                    Text("K")
                                        .font(.caption).fontWeight(.bold)
                                        .frame(width: 22, height: 22)
                                        .background(Circle().fill(Color.white))
                                        .foregroundColor(.black)
                                }
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
                
                HStack {
                    Button(action: {
                        toggleKreatynaForToday()
                    }) {
                        Image("protein")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .padding(4)
                            .background(isKreatynaToday() ? Color.green.opacity(0.7) : Color.gray.opacity(0.3))
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(isKreatynaToday() ? Color.green : Color.gray, lineWidth: 2)
                            )
                    }
                    .padding(.trailing, 8)
                    
                    Spacer()
                    
                    Button("Jednak nie wypiłem") {
                        selectedAmount = -50
                        showPopup = true
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    Button(action: {
                        showPastDayPopup = true
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 16))
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
            .onAppear{
                requestNotificationPermission()
                createNotificationActions()
                initializeBoilerModel()
                print("Boiler models count: \(boilerModels.count)")
                
                Task {
                    await scheduleAllWeeklyNotifications()
                }
                
                if boilerModels.isEmpty {
                    let initialBoiler = BoilerModel(amount: 2000)
                    modelContext.insert(initialBoiler)
                }
                updateDailyCount()
                NotificationCenter.default.addObserver(forName: NSNotification.Name("ADD_WATER"), object: nil, queue: .main) { notification in
                    if let amount = notification.userInfo?["amount"] as? Double {
                        addOrUpdateWaterProgress(amount)
                    }
                }
                
                // Uruchom dynamiczną aktualizację
                startDynamicUpdate()
                
//                    let calendar = Calendar.current
//                    guard let targetDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 16)) else { return }
//
//                    // Znajdź WaterProgress dla 24.05
//                    if let entry = waterProgresses.first(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
//                        entry.progress = 4500
//                        print("💧 Zmieniono ilość na 4300 ml dla WaterProgress z 24.05")
//                    } else {
//                        print("❌ Nie znaleziono wpisu WaterProgress z 24.05")
//                    }
//
//                    // Znajdź (lub dodaj) DailyCountModel dla 24.05
//                    if let dayEntry = dailyCountModels.first(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
//                        dayEntry.done = true
//                        print("✅ Ustawiono done = true dla DailyCountModel z 24.05")
//                    } else {
//                        let newEntry = DailyCountModel(dailyCount: 0, date: targetDate, done: true)
//                        modelContext.insert(newEntry)
//                        print("➕ Dodano DailyCountModel z done = true dla 24.05")
//                    }
//
//                    // Zapisz zmiany
//                    do {
//                        try modelContext.save()
//                        print("💾 Zmiany zapisane pomyślnie.")
//                    } catch {
//                        print("❌ Błąd zapisu: \(error.localizedDescription)")
//                    }


                
            }
            .onDisappear {
                // Zatrzymaj timer gdy aplikacja znika
                stopDynamicUpdate()
            }
            .onChange(of: currentTime) { _, _ in
                // Sprawdź czy to nowy dzień
                checkAndResetForNewDay()
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
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    Spacer()
                    
                    Button("Reset boilera") {
                        resetBoilerToFull()
                        showPopup = false
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
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
            .popover(isPresented: $showPastDayPopup) {
                VStack(spacing: 20) {
                    Text("Dodaj wodę do poprzedniego dnia")
                        .font(.headline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    DatePicker("Wybierz datę", selection: $selectedPastDate, in: ...Calendar.current.date(byAdding: .day, value: -1, to: Date())!, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding()
                        .onChange(of: selectedPastDate) { _, newDate in
                            let calendar = Calendar.current
                            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
                            isYesterdaySelected = calendar.isDate(newDate, inSameDayAs: yesterday)
                            
                            // Jeśli wybrano inny dzień niż wczoraj, resetuj wybór bojlera
                            if !isYesterdaySelected {
                                isPastDayBoiler = false
                            }
                        }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ilość wody (ml):")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Ilość wody", selection: $pastDayAmount) {
                            ForEach(Array(stride(from: 50, through: 1000, by: 50)), id: \.self) { value in
                                Text("\(value) ml")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Źródło wody:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if isYesterdaySelected {
                            HStack {
                                Button(action: {
                                    isPastDayBoiler = false
                                }) {
                                    HStack {
                                        Image(systemName: isPastDayBoiler ? "circle" : "checkmark.circle.fill")
                                            .foregroundColor(isPastDayBoiler ? .gray : .blue)
                                        Text("Woda")
                                    }
                                    .padding()
                                    .background(isPastDayBoiler ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    isPastDayBoiler = true
                                }) {
                                    HStack {
                                        Image(systemName: isPastDayBoiler ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(isPastDayBoiler ? .blue : .gray)
                                        Text("Boiler")
                                    }
                                    .padding()
                                    .background(isPastDayBoiler ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }
                            
                            if isPastDayBoiler {
                                Text("💡 Boiler działa tylko dla wczorajszego dnia")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.top, 5)
                            }
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Woda")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                            
                            Text("💡 Dla starszych dni dostępna jest tylko opcja 'Woda'")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 5)
                        }
                    }
                    
                    HStack(spacing: 20) {
                        Button("Anuluj") {
                            showPastDayPopup = false
                        }
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Button("Dodaj") {
                            addWaterToPastDay()
                            showPastDayPopup = false
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .presentationDetents([.height(600)])
                .presentationDragIndicator(.visible)
                .onAppear {
                    // Inicjalizacja przy pierwszym otwarciu popovera
                    let calendar = Calendar.current
                    let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
                    isYesterdaySelected = calendar.isDate(selectedPastDate, inSameDayAs: yesterday)
                    
                    print("DEBUG POPOVER: selectedPastDate = \(selectedPastDate)")
                    print("DEBUG POPOVER: yesterday = \(yesterday)")
                    print("DEBUG POPOVER: isYesterdaySelected = \(isYesterdaySelected)")
                    
                    // Jeśli wybrano inny dzień niż wczoraj, resetuj wybór bojlera
                    if !isYesterdaySelected {
                        isPastDayBoiler = false
                    }
                }
            }
            .padding()
        }
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
            existingEntry.done = calculateDynamicProgress() >= 4000
        } else {
            let newEntry = DailyCountModel(
                dailyCount: 0,
                date: today,
                done: calculateDynamicProgress() >= 4000
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
    
    private func calculateDynamicProgress() -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existingEntry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return existingEntry.progress
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
            } else if amountChange == 2000 {
                // Specjalny przypadek dla uzupełnienia bojlera
                boilerModel.amount = 2000
                do {
                    try modelContext.save()
                    print("Boiler reset to 2000 ml (full)")
                } catch {
                    print("Failed to save boiler model: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func addWaterToPastDay() {
        let calendar = Calendar.current
        let selectedDate = calendar.startOfDay(for: selectedPastDate)
        let today = calendar.startOfDay(for: Date())
        
        // Sprawdź czy wybrana data nie jest dzisiejsza ani przyszła
        guard selectedDate < today else {
            print("Nie można dodać wody do dzisiejszego lub przyszłego dnia")
            return
        }
        
        // Znajdź lub utwórz wpis dla wybranej daty
        var waterEntry: WaterProgress
        if let existingEntry = waterProgresses.first(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) {
            waterEntry = existingEntry
        } else {
            waterEntry = WaterProgress(progress: 0, maxProgress: 4000)
            waterEntry.date = selectedDate
            modelContext.insert(waterEntry)
        }
        
        // Dodaj wodę do wpisu
        waterEntry.progress += Double(pastDayAmount)
        
        // Obsługa bojlera dla wczorajszego dnia
        if isPastDayBoiler && isYesterdaySelected {
            if let boilerModel = boilerModels.first {
                let availableBoilerWater = min(pastDayAmount, boilerModel.amount)
                let remainingWater = pastDayAmount - availableBoilerWater
                
                // Odejmij dostępną wodę z dzisiejszego bojlera
                if availableBoilerWater > 0 {
                    boilerModel.amount -= availableBoilerWater
                    print("Odejmiono \(availableBoilerWater) ml z dzisiejszego bojlera dla wczorajszego dnia")
                }
                
                // Jeśli potrzebna dodatkowa woda, uzupełnij bojler i od razu odejmij potrzebną ilość
                if remainingWater > 0 {
                    boilerModel.amount = 2000 // Uzupełnij bojler do pełna
                    boilerModel.amount -= remainingWater // Od razu odejmij potrzebną dodatkową wodę
                    print("Uzupełniono bojler do 2000 ml i odjęto \(remainingWater) ml (dodatkowa woda)")
                }
                
                print("Symulacja użycia bojlera z wczoraj:")
                print("- Dostępna woda w bojlerze: \(availableBoilerWater) ml")
                if remainingWater > 0 {
                    print("- Dodatkowa woda (nie z bojlera): \(remainingWater) ml")
                }
                print("- Końcowy stan bojlera: \(boilerModel.amount) ml")
            }
        }
        
        // Zaktualizuj DailyCountModel dla wybranej daty
        var dailyCountEntry: DailyCountModel
        if let existingDailyEntry = dailyCountModels.first(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) {
            dailyCountEntry = existingDailyEntry
        } else {
            dailyCountEntry = DailyCountModel(dailyCount: 0, date: selectedDate, done: false)
            modelContext.insert(dailyCountEntry)
        }
        
        // Sprawdź czy cel dzienny został osiągnięty
        dailyCountEntry.done = waterEntry.progress >= 4000
        
        // Zapisz zmiany
        do {
            try modelContext.save()
            print("Dodano \(pastDayAmount) ml wody do dnia \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
            print("Nowy postęp dla tego dnia: \(waterEntry.progress) ml")
        } catch {
            print("Błąd podczas zapisywania: \(error.localizedDescription)")
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
        
        let waterCategory = UNNotificationCategory(
            identifier: "WATER_REMINDER",
            actions: [drinkAction, delayAction],
            intentIdentifiers: [],
            options: []
        )
        
        let resetCategory = UNNotificationCategory(
            identifier: "RESET_NOTIFICATIONS",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([waterCategory, resetCategory])
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RESET_NOTIFICATIONS"),
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.scheduleDailyNotificationsWithReset()
            }
        }
    }
    
    func calculateHourWater() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let startHour = 9
        let startMinute = 0
        
        let totalMinutesSinceStart = (currentHour - startHour) * 60 + (currentMinute - startMinute)
        
        let intervals = Int(ceil(Double(totalMinutesSinceStart) / 50.0))
        
        let recommendedWater = max(0, 250 * intervals)
        
        return recommendedWater
    }
    
    func scheduleDailyNotificationsWithReset() async {
        let center = UNUserNotificationCenter.current()
        
        center.removeAllPendingNotificationRequests()
        print("Usunięto wszystkie istniejące powiadomienia")
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let times = [
            (09, 0), (09, 50), (10, 40), (11, 30), (12, 20), (13, 10),
            (14, 0), (14, 50), (15, 40), (16, 30), (17, 20), (18, 10),
            (19, 0), (19, 50), (20, 40), (21, 00)
        ]
        
        print("\nRozpoczynam planowanie powiadomień na dziś...")
        var addedNotifications = 0
        
        let calendar = Calendar.current
        let now = Date()
        
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        
        let lastNotificationTime = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now)!
        let shouldPlanForTomorrow = now > lastNotificationTime
        
        if shouldPlanForTomorrow {
            todayComponents.day! += 1
        }
        
        var resetDateComponents = todayComponents
        resetDateComponents.day! += 1
        resetDateComponents.hour = 0
        resetDateComponents.minute = 0
        
        let resetTrigger = UNCalendarNotificationTrigger(
            dateMatching: resetDateComponents,
            repeats: false
        )
        
        let resetContent = UNMutableNotificationContent()
        resetContent.title = "Reset powiadomień"
        resetContent.sound = nil
        resetContent.categoryIdentifier = "RESET_NOTIFICATIONS"
        
        let resetRequest = UNNotificationRequest(
            identifier: "RESET_NOTIFICATION",
            content: resetContent,
            trigger: resetTrigger
        )
        
        do {
            try await center.add(resetRequest)
            print("Zaplanowano reset powiadomień na północ")
        } catch {
            print("Błąd podczas planowania resetu: \(error.localizedDescription)")
        }
        
        for (hour, minute) in times {
            var dateComponents = todayComponents
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let content = UNMutableNotificationContent()
            content.title = "Wypij szklankę wody"
            content.body = "Do wypicia: 250 ml | Powinieneś już wypić: \(250 * (times.firstIndex(where: { $0 == (hour, minute) })! + 1)) ml"
            content.sound = .default
            content.categoryIdentifier = "WATER_REMINDER"
            
            if let imageURL = Bundle.main.url(forResource: "water", withExtension: "png"),
               let attachment = try? UNNotificationAttachment(identifier: "waterIcon", url: imageURL, options: nil) {
                content.attachments = [attachment]
            }
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "TODAY_\(hour)_\(minute)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await center.add(request)
                addedNotifications += 1
                print("Zaplanowano powiadomienie na \(hour):\(minute)")
            } catch {
                print("Błąd podczas dodawania powiadomienia dla \(hour):\(minute) - \(error.localizedDescription)")
            }
        }
        
        print("\nZakończono planowanie powiadomień.")
        print("Zaplanowano \(addedNotifications) powiadomień na \(shouldPlanForTomorrow ? "jutro" : "dziś")")
        
        let requests = await center.pendingNotificationRequests()
        print("\nLista wszystkich zaplanowanych powiadomień:")
        print("Całkowita liczba powiadomień: \(requests.count)")
        
        print("\nPrzykładowe powiadomienia:")
        for request in requests.prefix(3) {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                print("ID: \(request.identifier)")
                print("Data: \(trigger.dateComponents)")
                print("---")
            }
        }
    }

    func scheduleAllWeeklyNotifications() async {
        await scheduleDailyNotificationsWithReset()
    }
    
    private func startDynamicUpdate() {
        // Zatrzymaj istniejący timer
        updateTimer?.invalidate()
        
        // Uruchom nowy timer co sekundę
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
        
        // Sprawdź czy to nowy dzień i zresetuj jeśli potrzeba
        checkAndResetForNewDay()
    }
    
    private func stopDynamicUpdate() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func checkAndResetForNewDay() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        if hour == 0 && minute == 0 {
            print("Nowy dzień - reset postępu wody i kreatyny")
            resetKreatynaForToday()
        }
    }
    
    private func toggleKreatynaForToday() {
        let today = Calendar.current.startOfDay(for: Date())
        if let entry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            entry.kreatyna.toggle()
            do { try modelContext.save() } catch { print(error) }
        } else {
            let newEntry = WaterProgress(progress: 0, maxProgress: 4000, kreatyna: true)
            newEntry.date = today
            modelContext.insert(newEntry)
            do { try modelContext.save() } catch { print(error) }
        }
    }
    
    private func isKreatynaToday() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        if let entry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return entry.kreatyna
        }
        return false
    }
    
    private func resetKreatynaForToday() {
        let today = Calendar.current.startOfDay(for: Date())
        if let entry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            entry.kreatyna = false
            do { try modelContext.save() } catch { print(error) }
        }
    }
    
    private func resetBoilerToFull() {
        if let boilerModel = boilerModels.first {
            boilerModel.amount = 2000
            do {
                try modelContext.save()
                print("Boiler reset to 2000 ml")
            } catch {
                print("Failed to reset boiler model: \(error.localizedDescription)")
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
        .modelContainer(for: [WaterProgress.self, BoilerModel.self, DailyCountModel.self])
}
