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

class WatchModel: ObservableObject {
    @Published var waterProgresses: [WaterProgress] = []
    @Published var appSettings: AppSettings?
    
    init() {
        loadAppSettings()
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
    
    private func loadAppSettings() {
        if appSettings == nil {
            appSettings = AppSettings()
        }
    }
    
    func updateDailyCount() {
        guard let settings = appSettings else { return }
        
        let completedDays = waterProgresses.filter { $0.progress >= 4000 }
        
        var uniqueDays: Set<Date> = []
        for entry in completedDays {
            let day = Calendar.current.startOfDay(for: entry.date)
            uniqueDays.insert(day)
        }
        
        settings.dailyCount = uniqueDays.count
    }
    
    func updateBoilerWater(by amount: Int) {
        guard var settings = appSettings else { return }
        settings.boilerWater -= amount
        if settings.boilerWater < 0 {
            settings.boilerWater = 0
        }
    }
    
    func resetAppSettings() {
        appSettings = AppSettings()
    }
}
