import SwiftUI
import SwiftData

struct WelcomeScreen: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @Environment(\.modelContext) private var modelContext
    @Query private var waterProgresses: [WaterProgress]


    var body: some View {
        VStack {
            let today = Calendar.current.startOfDay(for: Date())
            if waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) != nil {
                
                ContentView()
                
            }else{
                Button("Rozpocznij ten piękny dzień"){
                    
                }
                .padding()
                .background(Color.blue)
                .frame(width: 300, height: 50)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
                
            }
        }
}

#Preview {
    WelcomeScreen()
}
