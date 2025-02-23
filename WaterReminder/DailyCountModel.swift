import SwiftData
import Foundation

@Model
class DailyCountModel {
    var dailyCount: Int
    var date: Date
    var done: Bool
    
    init(dailyCount: Int, date: Date = Date(), done: Bool = false) {
        self.dailyCount = dailyCount
        self.date = date
        self.done = done
    }
}
