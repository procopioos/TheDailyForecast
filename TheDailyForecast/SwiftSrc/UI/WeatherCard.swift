import SwiftUI

struct WeatherCard: View {
    @Binding var condition: WeatherCondition
    @State private var now = Date()
    @State private var showSettings = false
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: now)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(condition.gradient)
                .animation(.easeInOut(duration: 0.8), value: condition)
                .frame(width: 800, height: 600)
                .shadow(radius: 5)



            VStack(alignment: .leading, spacing: 0) {
                
                HStack(alignment: .center) {
                    Text("The Daily Forecast")
                        .font(.custom("InstrumentSerif-Italic", size: 32))
                        .foregroundStyle(condition.textColor)

                    Spacer()

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(condition.secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 8)

                Spacer()
                    
                Text(timeString)
                    .font(.custom("JetBrainsMono-Regular", size: 16))
                    .foregroundStyle(condition.secondaryTextColor)
                
                Text("London")
                    .font(.custom("InstrumentSerif-Italic", size: 48))
                    .foregroundStyle(condition.textColor)

                Text("United Kingdom")
                    .font(.custom("JetBrainsMono-Regular", size: 16))
                    .foregroundStyle(condition.secondaryTextColor)
                    .padding(.top, 0.1)

                Spacer()

                Text("18°")
                    .font(.custom("InstrumentSerif-Regular", size: 90))
                    .foregroundStyle(condition.textColor)

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Label("12 km/h", systemImage: "wind")
                        .font(.custom("JetBrainsMono-Italic", size: 12))
                    Label("UV 5", systemImage: "sun.max.fill")
                        .font(.custom("JetBrainsMono-Italic", size: 12))
                    Label("64%", systemImage: "humidity.fill")
                        .font(.custom("JetBrainsMono-Italic", size: 12))
                }
                .font(.callout)
                .foregroundStyle(condition.secondaryTextColor)

                Spacer()
            }
            .padding(32)
            .frame(width: 600, height: 400, alignment: .leading)
            .onTapGesture {
                withAnimation {
                    let all = WeatherCondition.allCases
                    guard let idx = all.firstIndex(of: condition) else { return }
                    condition = all[(idx + 1) % all.count]
                }
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                now = Date()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
