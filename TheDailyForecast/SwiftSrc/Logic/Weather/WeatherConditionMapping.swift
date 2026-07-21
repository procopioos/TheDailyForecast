import Foundation

extension WeatherCondition {
    static func from(wmoCode: Int) -> WeatherCondition {
        switch wmoCode {
        case 0:
            return .sunny
        case 1, 2, 3, 45, 48:
            return .cloudy
        case 51, 53, 55, 61, 63, 65, 80, 81, 82:
            return .rainy
        case 71, 73, 75, 77, 85, 86:
            return .snowy
        case 95, 96, 99:
            return .stormy
        default:
            return .cloudy
        }
    }
}
