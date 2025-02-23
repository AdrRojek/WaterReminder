import Foundation
import SwiftData

@Model
class BoilerModel {
    var amount: Int = 0
    
    init(amount: Int = 2000) {
        self.amount = amount
    }
}

