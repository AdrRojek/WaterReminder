import SwiftUI
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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var waterProgresses: [WaterProgress]
    
    @State private var water: Int = 0
    
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
                        Text("Wypito!")
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
                
                if water != 0 {
                    Button("Dodaj") {
                        addWaterProgress(Double(water))
                        water = 0
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
            
            HStack {
                Button("Wypito 250 ml") {
                    addWaterProgress(250)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Wypito 500 ml") {
                    addWaterProgress(500)
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
        }
        .padding()
    }
    

    private func addWaterProgress(_ amount: Double) {
        let newEntry = WaterProgress(progress: amount, maxProgress: 4000)
        modelContext.insert(newEntry)
    }
    
    private func calculateTotalProgress() -> Double {
        waterProgresses.reduce(0) { $0 + $1.progress }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WaterProgress.self)
}
