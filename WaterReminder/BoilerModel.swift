import Foundation
import SwiftData

@Model
class BoilerModel {
    var amount: Int 
    
    init(amount: Int = 2000) {
        self.amount = amount
    }
}

