import Foundation

struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
    let hourly: HourlyWeather?
}

struct CurrentWeather: Codable {
    let temperature2m: Double
    let relativeHumidity2m: Int
    let windSpeed10m: Double
    let weatherCode: Int
    let time: String

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case windSpeed10m = "wind_speed_10m"
        case weatherCode = "weather_code"
        case time
    }
}

struct HourlyWeather: Codable {
    let time: [String]
    let uvIndex: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case uvIndex = "uv_index"
    }
}
