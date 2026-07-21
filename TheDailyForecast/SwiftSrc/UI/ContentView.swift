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
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
            NSApplication.shared.terminate(nil)
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 700)
}
