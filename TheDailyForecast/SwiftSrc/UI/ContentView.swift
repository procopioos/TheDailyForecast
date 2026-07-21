import SwiftUI

struct ContentView: View {
    @StateObject private var weatherService = WeatherService.shared

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            WeatherCard(weatherData: weatherService.currentWeather)
        }
        .onAppear {
            weatherService.startAutoRefresh()
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 700)
}
