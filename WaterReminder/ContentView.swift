import SwiftUI
import SwiftData
import UserNotifications

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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var waterProgresses: [WaterProgress]
    
    @State private var water: Int = 0
    @State private var showPopup = false
    @State private var selectedAmount: Int = -50
    @State private var showResetPopup = false
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "drop.fill")
                    .resizable()
                    .frame(width: 50, height: 70)
                    .foregroundColor(.blue)
                
                ProgressView(value: calculateTotalProgress(), total: 4000) {
                    if calculateTotalProgress() < 4000 {
                        Text("Jeszcze \(Int(4000 - calculateTotalProgress())) ml")
                    } else {
                        Text("Wypiłeś już \(Int(calculateTotalProgress())) ml")
                    }
                }
                .frame(width: 200, height: 20)
            }
            .padding()
            
            HStack {
                Picker(selection: $water, label: Text("Ile wypiłeś?")) {
                    ForEach(Array(stride(from: 50, through: 1000, by: 50)), id: \.self) { value in
                        Text("\(value) ml")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                Button("Dodaj") {
                    addOrUpdateWaterProgress(Double(water))
                    water = 0
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            
            HStack {
                Button("Wypito 250 ml") {
                    addOrUpdateWaterProgress(250)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Wypito 500 ml") {
                    addOrUpdateWaterProgress(500)
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            
            Text("Historia z ostatnich dni")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(waterProgresses.sorted(by: { $0.date > $1.date })) { entry in
                        HStack {
                            Text("\(entry.date.formatted(date: .abbreviated, time: .shortened))")
                            Spacer()
                            Text("\(Int(entry.progress)) ml")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 300)
            
            Spacer()
            
            Button("Jednak nie wypiłem") {
                selectedAmount = -50
                showPopup = true
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .sheet(isPresented: $showPopup) {
            HStack{
                Button("Cofnij"){
                    showPopup = false
                }
            }
            VStack {
                Text("Ile chcesz odjąć?")
                    .font(.headline)
                    .padding()
                
                Picker("Ile chcesz odjąć?", selection: $selectedAmount) {
                    ForEach(Array(stride(from: 0, through: 1000, by: 50)), id: \.self) { value in
                        Text("\((value * -1)) ml")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 150)
                
                Button("Zatwierdź") {
                    subtractWaterProgress(Double(selectedAmount))
                    showPopup = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
                
                Button("Resetuj"){
                    showResetPopup = true
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                
            }
            .padding()
        }
        .popover(isPresented: $showResetPopup){
            VStack(spacing: 50){
                Text("Czy na pewno chcesz zresetować?")
            
            
            HStack(spacing: 30){
                
                Button("Nie"){
                    showResetPopup = false
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                
                Button("Tak"){
                    resetWater()
                    showResetPopup = false
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                
            }
            }
        }
        .padding()
    }
    
    private func addOrUpdateWaterProgress(_ amount: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existingEntry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existingEntry.progress += amount
        } else {
            let newEntry = WaterProgress(progress: amount, maxProgress: 4000)
            modelContext.insert(newEntry)
        }
    }
    
    private func subtractWaterProgress(_ amount: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existingEntry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existingEntry.progress -= amount
            if existingEntry.progress < 0 {
                existingEntry.progress = 0
            }
        }
    }
    
    private func resetWater(){
        let today = Calendar.current.startOfDay(for: Date())
        
        if let existingEntry = waterProgresses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            if existingEntry.progress != 0 {
                existingEntry.progress = 0
            } else {
                Text("Nic dzisiaj nie wypiłeś")
            }
        }
    }
    
    private func calculateTotalProgress() -> Double {
        waterProgresses.reduce(0) { $0 + $1.progress }
    }
    
    private func printDatabaseContents() {
        for entry in waterProgresses {
            print("Data: \(entry.date), Ilość: \(entry.progress) ml")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WaterProgress.self)
}
