import Foundation
import SwiftData

@Model
class WaterProgress {
    var progress: Double
    var maxProgress: Double
    var date: Date
    var startTime: Date

    init(progress: Double = 0.0, maxProgress: Double = 4000, startTime: Date = Date()) {
        self.progress = progress
        self.maxProgress = maxProgress
        self.date = Date()
        self.startTime = startTime
    }
}


class WatchModel: ObservableObject {
    @Published var waterProgresses: [WaterProgress] = []
    
        func addWaterProgress(_ progress: Double, maxProgress: Double = 4000) {
        let newProgress = WaterProgress(progress: progress, maxProgress: maxProgress)
        waterProgresses.append(newProgress)
    }
    
    
}
