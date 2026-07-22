import SwiftUI

enum WeatherCondition: CaseIterable {
    case sunny, cloudy, rainy, snowy, stormy

    var gradient: LinearGradient {
        switch self {
        case .sunny:  LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .cloudy: LinearGradient(colors: [.gray, .gray.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .rainy:  LinearGradient(colors: [.indigo, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .snowy:  LinearGradient(colors: [.white, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .stormy: LinearGradient(colors: [.indigo, .gray.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var textColor: Color {
        switch self {
        case .snowy: return .black
        case .sunny, .cloudy, .rainy, .stormy: return .white
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .snowy: return .black.opacity(0.6)
        case .sunny, .cloudy, .rainy, .stormy: return .white.opacity(0.7)
        }
    }

    var panelColor: Color {
        switch self {
        case .sunny:  return .cyan
        case .cloudy: return .gray
        case .rainy:  return .indigo
        case .snowy:  return .cyan
        case .stormy: return .indigo
        }
    }

    var name: String {
        switch self {
        case .sunny:  return "Sunny"
        case .cloudy: return "Cloudy"
        case .rainy:  return "Rainy"
        case .snowy:  return "Snowy"
        case .stormy: return "Stormy"
        }
    }
}
