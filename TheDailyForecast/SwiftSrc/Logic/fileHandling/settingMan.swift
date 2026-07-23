//
//  settingMan.swift
//  TheDailyForecast
//
//  Created by Simone Procopio on 21/07/2026.
//

import Foundation
import Combine

enum TemperatureUnit: String, Codable, CaseIterable {
    case celsius
    case fahrenheit

    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}

struct AppConfig: Codable {
    var city: String
    var temperatureUnit: TemperatureUnit

    static let `default` = AppConfig(
        city: "New York",
        temperatureUnit: .celsius
    )
}

class SettingMan: ObservableObject {
    static let shared = SettingMan()

    @Published var config: AppConfig {
        didSet { save() }
    }

    private let fileName = "config.json"

    private var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("com.procopioos.TheDailyForecast")
        return dir.appendingPathComponent(fileName)
    }

    private init() {
        self.config = AppConfig.default
        self.config = SettingMan.loadConfig(from: fileURL) ?? AppConfig.default
    }

    private static func loadConfig(from url: URL) -> AppConfig? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("No config file found, using defaults")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(AppConfig.self, from: data)
            print("Config loaded: city=\(config.city), unit=\(config.temperatureUnit.rawValue)")
            return config
        } catch {
            print("Failed to load config, using defaults: \(error.localizedDescription)")
            return nil
        }
    }

    func save() {
        let dir = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        do {
            let data = try JSONEncoder().encode(config)
            let formatted = try JSONSerialization.data(
                withJSONObject: try JSONSerialization.jsonObject(with: data),
                options: [.prettyPrinted, .sortedKeys]
            )
            try formatted.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save config: \(error.localizedDescription)")
        }
    }

    func resetToDefaults() {
        config = AppConfig.default
    }
}
