//
//  locationCoord.swift
//  TheDailyForecast
//
//  Created by Simone Procopio on 21/07/2026.
//

import Foundation
import CoreLocation
import Combine

class LocationService: ObservableObject {
    static let shared = LocationService()

    @Published var locationName: String?
    @Published var country: String?
    @Published var latitude: Double?
    @Published var longitude: Double?

    private let geocoder = CLGeocoder()

    init() {
        Task {
            await updateLocation("Parigi")
        }
    }

    func updateLocation(_ name: String) async {
        do {
            let placemarks = try await geocoder.geocodeAddressString(name)
            guard let placemark = placemarks.first,
                  let coordinate = placemark.location?.coordinate else { return }
            await MainActor.run {
                self.latitude = coordinate.latitude
                self.longitude = coordinate.longitude
                self.locationName = placemark.locality ?? name
                self.country = placemark.country ?? ""
            }
            print("Location acquired! \(latitude ?? 0), \(longitude ?? 0): \(locationName ?? ""), \(country ?? "")")
        } catch {
            print("Geocoding failed: \(error.localizedDescription)")
        }
    }
}
