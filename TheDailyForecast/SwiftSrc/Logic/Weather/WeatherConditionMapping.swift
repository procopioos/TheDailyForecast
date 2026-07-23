import Foundation

extension WeatherCondition {
    static func from(wmoCode: Int) -> WeatherCondition {
        switch wmoCode {
        case 0, 1, 2, 51:
            return .sunny
        case 3, 45, 48:
            return .cloudy
        case 53, 55, 61, 63, 65, 80, 81:
            return .rainy
        case 56, 57, 71, 73, 75, 77, 85, 86:
            return .snowy
        case 82, 95, 96, 99:
            return .stormy
        default:
            return .sunny
        }
    }
}
