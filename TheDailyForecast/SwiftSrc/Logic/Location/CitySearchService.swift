//
//  CitySearchService.swift
//  TheDailyForecast
//
//  Created by Simone Procopio on 21/07/2026.
//

import Foundation

struct CityResult: Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let countryCode: String
    let admin1: String?

    var displayName: String {
        if let region = admin1, region != name {
            return "\(name), \(region), \(country)"
        }
        return "\(name), \(country)"
    }
}

struct PhotonResponse: Codable {
    let type: String
    let features: [PhotonFeature]
}

struct PhotonFeature: Codable {
    let properties: PhotonProperties
    let geometry: PhotonGeometry
}

struct PhotonProperties: Codable {
    let name: String?
    let state: String?
    let country: String?
    let countryCode: String?
    let osmId: Int?

    enum CodingKeys: String, CodingKey {
        case name, state, country
        case countryCode = "countrycode"
        case osmId = "osm_id"
    }
}

struct PhotonGeometry: Codable {
    let type: String
    let coordinates: [Double]
}

class CitySearchService {
    static let shared = CitySearchService()

    private let baseURL = "https://photon.komoot.io/api/"
    private var currentTask: Task<[CityResult], Never>?

    private init() {}

    func search(query: String) async -> [CityResult] {
        currentTask?.cancel()

        guard query.count >= 3 else { return [] }

        let task = Task<[CityResult], Never> {
            var components = URLComponents(string: self.baseURL)
            components?.queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: "8"),
                URLQueryItem(name: "lang", value: "en"),
                URLQueryItem(name: "layer", value: "city"),
                URLQueryItem(name: "layer", value: "district")
            ]

            guard let url = components?.url else { return [] }

            var request = URLRequest(url: url)
            request.setValue("TheDailyForecast/1.0", forHTTPHeaderField: "User-Agent")

            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(PhotonResponse.self, from: data)
                return response.features.compactMap { self.convertToCityResult($0) }
                    .reduce(into: [CityResult]()) { acc, city in
                        if !acc.contains(where: { $0.name == city.name && $0.latitude == city.latitude && $0.longitude == city.longitude }) {
                            acc.append(city)
                        }
                    }
            } catch {
                print("City search failed: \(error.localizedDescription)")
                return []
            }
        }

        currentTask = task
        return await task.value
    }

    func cancelSearch() {
        currentTask?.cancel()
    }

    private func convertToCityResult(_ feature: PhotonFeature) -> CityResult? {
        guard feature.geometry.coordinates.count >= 2 else { return nil }

        let lon = feature.geometry.coordinates[0]
        let lat = feature.geometry.coordinates[1]
        let name = feature.properties.name ?? ""
        let country = feature.properties.country ?? ""
        let countryCode = feature.properties.countryCode ?? ""
        let admin1 = feature.properties.state
        let id = feature.properties.osmId ?? 0

        guard !name.isEmpty else { return nil }

        return CityResult(
            id: id,
            name: name,
            latitude: lat,
            longitude: lon,
            country: country,
            countryCode: countryCode,
            admin1: admin1
        )
    }
}
