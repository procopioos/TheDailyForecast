import SwiftUI

struct WeatherCard: View {
    var weatherData: WeatherData?
    @State private var now = Date()
    @State private var showSettings = false
    @State private var showSunny = false
    @State private var clockTimer: Timer?
    @ObservedObject private var locationService = LocationService.shared
    @ObservedObject private var settingMan = SettingMan.shared

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var condition: WeatherCondition {
        weatherData?.condition ?? .sunny
    }

    private var displayTemperature: Int {
        guard let temp = weatherData?.temperature else { return 0 }
        switch settingMan.config.temperatureUnit {
        case .celsius: return Int(temp)
        case .fahrenheit: return Int(temp * 9 / 5 + 32)
        }
    }

    private var tempUnitSymbol: String {
        settingMan.config.temperatureUnit.symbol
    }

    private var timeString: String {
        timeFormatter.string(from: now)
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

                Spacer()

                Text("\(displayTemperature)°")
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

                if #available(macOS 26.0, *) {
                    Button {
                        showSunny.toggle()
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
            }
            .frame(width: 800, height: 600, alignment: .trailing)
            .padding(.trailing, 48)
        }
        .onAppear {
            clockTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                now = Date()
            }
        }
        .onDisappear {
            clockTimer?.invalidate()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .overlay {
            if #available(macOS 26.0, *), showSunny {
                SunnyView(
                    weatherData: weatherData,
                    locationName: locationService.locationName,
                    condition: condition,
                    onDismiss: { showSunny = false }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .animation(.easeOut(duration: 0.25), value: showSunny)
            }
        }
    }
}
