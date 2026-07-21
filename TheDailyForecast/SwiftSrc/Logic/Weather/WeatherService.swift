import Foundation
import Combine

class WeatherService: ObservableObject {
    static let shared = WeatherService()

    @Published var currentWeather: WeatherData?

    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private var timer: Timer?
    private var locationCancellable: AnyCancellable?

    private var apiURL: URL? {
        guard let lat = LocationService.shared.latitude,
              let lon = LocationService.shared.longitude else { return nil }
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code"),
            URLQueryItem(name: "hourly", value: "uv_index"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        return components?.url
    }

    func fetchWeather() async throws -> WeatherData {
        guard let url = apiURL else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

        let current = response.current
        let uvIndex = findCurrentUVIndex(response: response, currentTime: current.time)

        return WeatherData(
            temperature: current.temperature2m,
            humidity: current.relativeHumidity2m,
            windSpeed: current.windSpeed10m,
            uvIndex: uvIndex,
            condition: WeatherCondition.from(wmoCode: current.weatherCode)
        )
    }

    func startAutoRefresh(interval: TimeInterval = 300) {
        stopAutoRefresh()
        observeLocation()
        Task {
            await refresh()
        }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.refresh()
            }
        }
    }

    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }

    func updateLocation(_ name: String) async {
        await LocationService.shared.updateLocation(name)
        await refresh()
    }

    @MainActor
    private func refresh() {
        Task {
            do {
                currentWeather = try await fetchWeather()
            } catch {
                print("Weather fetch failed: \(error.localizedDescription)")
            }
        }
    }

    private func observeLocation() {
        locationCancellable = LocationService.shared.$latitude
            .combineLatest(LocationService.shared.$longitude)
            .sink { [weak self] lat, lon in
                guard lat != nil, lon != nil else { return }
                Task { await self?.refresh() }
            }
    }

    private func findCurrentUVIndex(response: OpenMeteoResponse, currentTime: String) -> Double {
        guard let hourly = response.hourly else { return 0 }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        guard let currentISO = formatter.date(from: currentTime) else { return 0 }

        for (index, timeString) in hourly.time.prefix(hourly.uvIndex.count).enumerated() {
            guard index < hourly.uvIndex.count,
                  let hourISO = formatter.date(from: timeString) else { continue }

            if Calendar.current.isDate(currentISO, equalTo: hourISO, toGranularity: .hour) {
                return hourly.uvIndex[index]
            }
        }

        return 0
    }
}
