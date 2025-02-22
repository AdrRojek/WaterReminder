import Foundation
import SwiftData
import Combine

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

class WaterModel: ObservableObject {
    @Published var waterProgresses: [WaterProgress] = []
    @Published var appSettings: AppSettings?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadAppSettings()
    }
    
    func addWaterProgress(_ progress: Double, maxProgress: Double = 4000) {
        let newProgress = WaterProgress(progress: progress, maxProgress: maxProgress)
        waterProgresses.append(newProgress)
        updateDailyCount()
    }
    
    func subtractWaterProgress(_ amount: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        if let existingEntry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existingEntry.progress -= amount
            if existingEntry.progress < 0 {
                existingEntry.progress = 0
            }
        }
    }
    
    func resetWater() {
        let today = Calendar.current.startOfDay(for: Date())
        if let existingEntry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existingEntry.progress = 0
        }
    }
    
    func updateBoilerWater(by amount: Int) {
        guard var settings = appSettings else { return }
        settings.boilerWater -= amount
        if settings.boilerWater < 0 {
            settings.boilerWater = 0
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
    
    private func loadAppSettings() {
        if appSettings == nil {
            appSettings = AppSettings()
        }
    }
}
