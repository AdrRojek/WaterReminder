import Foundation
import SwiftData

@Model
class WaterProgress {
    var progress: Double
    var maxProgress: Double
    var date: Date
    var kreatyna: Bool = false
    
    init(progress: Double = 0.0, maxProgress: Double = 4000, kreatyna: Bool = false) {
        self.progress = progress
        self.maxProgress = maxProgress
        self.date = Date()
        self.kreatyna = kreatyna
    }
}

class WaterModel: ObservableObject {
    @Published var waterProgresses: [WaterProgress] = []
    
    func addWaterProgress(_ progress: Double, maxProgress: Double = 4000) {
        let newProgress = WaterProgress(progress: progress, maxProgress: maxProgress)
        waterProgresses.append(newProgress)
    }
    
    
}
