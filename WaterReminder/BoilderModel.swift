import Foundation
import SwiftData

@Model
class BoilderModel {
    var amount: Int = 0
    
    init(amount: Int = 2000) {
        self.amount = amount
    }
}

