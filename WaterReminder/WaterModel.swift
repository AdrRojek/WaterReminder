import Foundation
import SwiftData

@Model
class WaterProgress {
    var progress: Double
    var maxProgress: Double
    var date: Date
    
    init(progress: Double = 0.0, maxProgress: Double = 4000, date: Date = Date()) {
        self.progress = progress
        self.maxProgress = maxProgress
        self.date = date
    }
}

@Model
class AppSettings {
    var boilerWater: Int
    var dailyCount: Int
    
    init(boilerWater: Int = 2000, dailyCount: Int = 0) {
        self.boilerWater = boilerWater
        self.dailyCount = dailyCount
    }
}

class WaterModel: ObservableObject {
    @Published var waterProgresses: [WaterProgress] = []
    @Published var appSettings: AppSettings?
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAppSettings()
        fetchSettings()
    }
    
    func setup(modelContext: ModelContext) {
            self.modelContext = modelContext
            fetchSettings()
        }
    
    private func fetchSettings() {
            let descriptor = FetchDescriptor<AppSettings>()
            do {
                appSettings = try modelContext.fetch(descriptor).first ?? AppSettings()
                if appSettings?.boilerWater == nil {
                    appSettings = AppSettings()
                    modelContext.insert(appSettings!)
                }
            } catch {
                print("Failed to fetch settings")
            }
        }
    
    func addWaterProgress(_ progress: Double, maxProgress: Double = 4000, date: Date = Date()) {
        let today = Calendar.current.startOfDay(for: date)
        
        if let existingEntry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existingEntry.progress += progress
        } else {
            let newProgress = WaterProgress(progress: progress, maxProgress: maxProgress, date: today)
            waterProgresses.append(newProgress)
        }
        
        updateDailyCount()
    }
    
    func loadAppSettings() {
        let request = FetchDescriptor<AppSettings>()
                if let existingSettings = try? modelContext.fetch(request).first {
                    appSettings = existingSettings
                } else {
                    let newSettings = AppSettings()
                    modelContext.insert(newSettings)
                    appSettings = newSettings
                    saveAppSettings()
                }
    }
    
    func saveAppSettings() {
            do {
                try modelContext.save()
            } catch {
                print("Błąd zapisu: \(error)")
            }
        }
    
    func updateDailyCount() {
        guard let settings = appSettings else { return }
        
        var dailyProgress: [Date: Double] = [:]
        
        for entry in waterProgresses {
            let day = Calendar.current.startOfDay(for: entry.date)
            dailyProgress[day] = (dailyProgress[day] ?? 0) + entry.progress
        }
        
        print("Daily progress: \(dailyProgress)")
        
        let completedDays = dailyProgress.filter { $0.value >= 4000 }
        
        print("Completed days: \(completedDays)")
        
        settings.dailyCount = completedDays.count
        print("Updated dailyCount: \(settings.dailyCount)")
    }
    
    func updateBoilerWater(by amount: Int) {
        let currentValue = appSettings?.boilerWater ?? 2000
        let newValue = max(0, min(currentValue - amount, 2000))
        appSettings?.boilerWater = newValue
        try? modelContext.save()
    }
    
    func resetAppSettings() {
        appSettings = AppSettings()
    }
}
