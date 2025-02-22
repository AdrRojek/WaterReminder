import Foundation
import SwiftData

@Model
class WaterProgress {
    var progress: Double
    var maxProgress: Double
    var date: Date
    
    init(progress: Double = 0.0, maxProgress: Double = 4000) {
        self.progress = progress
        self.maxProgress = maxProgress
        self.date = Date()
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
    
    func addWaterProgress(_ progress: Double, maxProgress: Double = 4000) {
        let newProgress = WaterProgress(progress: progress, maxProgress: maxProgress)
        waterProgresses.append(newProgress)
        updateDailyCount()
    }
    
    private func loadAppSettings() {
        if appSettings == nil {
            appSettings = AppSettings()
        }
    }
    
    func updateDailyCount() {
        guard let settings = appSettings else { return }
        
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
        
        settings.dailyCount = count
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
