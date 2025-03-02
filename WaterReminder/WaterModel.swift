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

class WaterModel: ObservableObject {
    @Published var waterProgresses: [WaterProgress] = []
    
    func addWaterProgress(_ progress: Double, maxProgress: Double = 4000) {
        let newProgress = WaterProgress(progress: progress, maxProgress: maxProgress)
        waterProgresses.append(newProgress)
    }
    
    
}
