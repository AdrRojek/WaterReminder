import SwiftUI
import SwiftData

@Model
class WaterProgress {
    var progress: Double
    var maxProgress: Double
    
    init(progress: Double = 0.0, maxProgress: Double = 4000) {
        self.progress = progress
        self.maxProgress = maxProgress
    }
}

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var waterProgresses: [WaterProgress]
    
    @State private var water: Int = 0
    
    private var waterProgress: WaterProgress {
        if let existing = waterProgresses.first {
            return existing
        } else {
            let newProgress = WaterProgress()
            modelContext.insert(newProgress)
            return newProgress
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "drop.fill")
                    .resizable()
                    .frame(width: 50, height: 70)
                    .foregroundColor(.blue)
                
                ProgressView(value: waterProgress.progress / waterProgress.maxProgress) {
                    if waterProgress.progress < waterProgress.maxProgress {
                        Text("Jeszcze \(Int(waterProgress.maxProgress - waterProgress.progress)) ml")
                    } else {
                        Text("Wypito! Wypiłeś już \(Int(waterProgress.progress))ml")
                    }
                }
                .frame(width: 250, height: 20)
            }
            .padding()
            
            HStack {
                Picker(selection: $water, label: Text("Ile wypiles?")) {
                    ForEach(Array(stride(from: 0, through: 1000, by: 50)), id: \.self) {
                        Text("\($0) ml")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                    Button("Serio tyle wypito") {
                        waterProgress.progress += Double(water)
                        water = 0
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
            }
            .padding()
            
            VStack {
                Text("apk3a3!")
                    .font(.title)
                    .padding()
                
                Button("Wypito 250ml") {
                    waterProgress.progress += 250
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Wypito 500ml") {
                    waterProgress.progress += 500
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .onAppear {
            if waterProgresses.isEmpty {
                modelContext.insert(WaterProgress())
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WaterProgress.self)
}
