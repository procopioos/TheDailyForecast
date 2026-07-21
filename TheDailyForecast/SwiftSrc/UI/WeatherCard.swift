import SwiftUI

struct WeatherCard: View {
    var weatherData: WeatherData?
    @State private var now = Date()
    @State private var showSettings = false
    @ObservedObject private var locationService = LocationService.shared

    private var condition: WeatherCondition {
        weatherData?.condition ?? .sunny
    }
    
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
                
                Text("The Daily Forecast")
                    .font(.custom("InstrumentSerif-Italic", size: 32))
                    .foregroundStyle(condition.textColor)
                    .padding(.bottom, 8)

                Spacer()
                    
                Text(timeString)
                    .font(.custom("JetBrainsMono-Regular", size: 16))
                    .foregroundStyle(condition.secondaryTextColor)
                
                Text(locationService.locationName ?? "")
                    .font(.custom("InstrumentSerif-Italic", size: 48))
                    .foregroundStyle(condition.textColor)

                Text(locationService.country ?? "")
                    .font(.custom("JetBrainsMono-Regular", size: 16))
                    .foregroundStyle(condition.secondaryTextColor)
                    .padding(.top, 0.1)

                Spacer()

                Text("\(Int(weatherData?.temperature ?? 0))°")
                    .font(.custom("InstrumentSerif-Regular", size: 90))
                    .foregroundStyle(condition.textColor)

                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Label("\(Int(weatherData?.windSpeed ?? 0)) km/h", systemImage: "wind")
                        .font(.custom("JetBrainsMono-Italic", size: 12))
                        .foregroundStyle(condition.textColor)
                    Label("UV \(Int(weatherData?.uvIndex ?? 0))", systemImage: "sun.max.fill")
                        .font(.custom("JetBrainsMono-Italic", size: 12))
                        .foregroundStyle(condition.textColor)
                    Label("\(weatherData?.humidity ?? 0)%", systemImage: "humidity.fill")
                        .font(.custom("JetBrainsMono-Italic", size: 12))
                        .foregroundStyle(condition.textColor)
                }

                Spacer()
            }
            .padding(32)
            .frame(width: 600, height: 400, alignment: .leading)

            VStack {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(condition.secondaryTextColor)
                }
                .buttonStyle(.plain)
                .padding(.top, 32)

                Spacer()

                Button {
                    print("Sunny Placeholder!")
                } label: {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(condition.secondaryTextColor)
                        .padding(10)
                        .background {
                            Circle()
                                .fill(.white.opacity(0.2))
                        }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 32)
            }
            .frame(width: 800, height: 600, alignment: .trailing)
            .padding(.trailing, 48)
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
