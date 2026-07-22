# External API Reference

This document covers all external services and APIs consumed by The Daily Forecast.

---

## Table of Contents

1. [Open-Meteo API](#1-open-meteo-api) — Weather Data
2. [Photon Geocoding API](#2-photon-geocoding-api) — City Search
3. [Apple CLGeocoder](#3-apple-clgeocoder) — Location Resolution
4. [LocalLLMClient / Foundation Models](#4-localllmclient--foundation-models) — On-device AI
5. [Data Flow](#5-data-flow)
6. [WMO Weather Code Mapping](#6-wmo-weather-code-mapping)

---

## 1. Open-Meteo API

Free, open-source weather API. No API key required.

**Source files:** `WeatherService.swift`, `WeatherResponse.swift`

### Endpoint

```
GET https://api.open-meteo.com/v1/forecast
```

### Query Parameters

| Parameter    | Type   | Value                                      | Description                              |
|--------------|--------|--------------------------------------------|------------------------------------------|
| `latitude`   | Double | Current latitude from `LocationService`    | Latitude of the location                 |
| `longitude`  | Double | Current longitude from `LocationService`   | Longitude of the location                |
| `current`    | String | `temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code` | Current weather fields to return |
| `hourly`     | String | `uv_index`                                 | Hourly fields to return                  |
| `timezone`   | String | `auto`                                     | Timezone for hourly data                 |

### Response Structure

```json
{
  "current": {
    "temperature_2m": 22.5,
    "relative_humidity_2m": 65,
    "wind_speed_10m": 12.3,
    "weather_code": 0,
    "time": "2026-07-22T14:00"
  },
  "hourly": {
    "time": ["2026-07-22T00:00", "2026-07-22T01:00", "..."],
    "uv_index": [0.0, 0.1, "..."]
  }
}
```

### Decoded Types

```swift
struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
    let hourly: HourlyWeather?
}

struct CurrentWeather: Codable {
    let temperature2m: Double        // "temperature_2m"
    let relativeHumidity2m: Int      // "relative_humidity_2m"
    let windSpeed10m: Double         // "wind_speed_10m"
    let weatherCode: Int             // "weather_code"
    let time: String                 // ISO 8601 datetime
}

struct HourlyWeather: Codable {
    let time: [String]              // Array of ISO 8601 datetimes
    let uvIndex: [Double]           // "uv_index"
}
```

### UV Index Extraction

The UV index is not part of the `current` block. The app finds the current hour's UV index by matching `current.time` against `hourly.time` arrays, comparing at hour granularity.

```swift
// WeatherService.swift:92-110
private func findCurrentUVIndex(response: OpenMeteoResponse, currentTime: String) -> Double
```

### Usage Pattern

- **On launch:** Fetched immediately via `LocationService.init()` chain.
- **Auto-refresh:** Timer fires every **300 seconds (5 minutes)** via `startAutoRefresh()`.
- **Location change:** Re-fetches whenever `LocationService.latitude` or `longitude` changes (Combine pipeline).

### Error Handling

- `URLError(.badURL)` thrown if `LocationService` coordinates are nil.
- `DecodingError` thrown on malformed JSON.
- Errors are caught in `refresh()` and logged to console via `print()`. The UI remains on the last known weather data.

### Authentication

None. Open-Meteo is a free, keyless API.

### Rate Limits

Open-Meteo does not enforce strict rate limits for non-commercial use. The app self-throttles via the 5-minute refresh interval.

---

## 2. Photon Geocoding API

Open-source geocoding service by Komoot, based on OpenStreetMap data. No API key required.

**Source file:** `CitySearchService.swift`

### Endpoint

```
GET https://photon.komoot.io/api/
```

### Query Parameters

| Parameter | Type   | Value             | Description                              |
|-----------|--------|-------------------|------------------------------------------|
| `q`       | String | User input        | Search query (city name)                 |
| `limit`   | Int    | `8`               | Maximum number of results                |
| `lang`    | String | `en`              | Response language                        |
| `layer`   | String | `city`            | OSM layer filter (included once)         |
| `layer`   | String | `district`        | OSM layer filter (included twice)        |

> Note: `layer` is sent twice as a repeated query parameter. This restricts results to cities and districts only.

### Request Headers

| Header      | Value                    | Description              |
|-------------|--------------------------|--------------------------|
| `User-Agent`| `TheDailyForecast/1.0`   | App identifier           |

### Response Structure (GeoJSON)

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "properties": {
        "name": "Catania",
        "state": "Sicily",
        "country": "Italy",
        "countrycode": "IT",
        "osm_id": 123456
      },
      "geometry": {
        "type": "Point",
        "coordinates": [15.0873, 37.5021]
      }
    }
  ]
}
```

### Decoded Types

```swift
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
    let countryCode: String?     // "countrycode"
    let osmId: Int?              // "osm_id"
}

struct PhotonGeometry: Codable {
    let type: String
    let coordinates: [Double]    // [longitude, latitude]
}
```

### Result Mapping

Each `PhotonFeature` is converted to a `CityResult`:

```swift
struct CityResult: Identifiable {
    let id: Int                  // from osm_id
    let name: String
    let latitude: Double         // coordinates[1]
    let longitude: Double        // coordinates[0]
    let country: String
    let countryCode: String
    let admin1: String?          // from state
}
```

Coordinates are extracted as `[longitude, latitude]` — standard GeoJSON order.

### Throttling and Cancellation

- **Debounce:** 300ms delay after keystroke before firing the request (`SettingsView.swift:164`).
- **Minimum query length:** 3 characters required before any request is made.
- **In-flight cancellation:** Previous `Task` is cancelled before starting a new one.
- **Deduplication:** Results with matching `name` + `latitude` + `longitude` are filtered out.

### Error Handling

- Invalid URL construction returns an empty array `[]`.
- Network or decoding failures are caught and logged; an empty array is returned.

### Authentication

None. Photon is a free, open-source API.

### Rate Limits

Photon does not publish strict rate limits. The app's debounce and cancellation logic prevents excessive requests.

---

## 3. Apple CLGeocoder

Native Apple framework for converting addresses to coordinates (and vice versa).

**Source file:** `locationCoord.swift`

### Usage

```swift
let geocoder = CLGeocoder()
let placemarks = try await geocoder.geocodeAddressString(name)
```

Takes a city name string and returns `CLPlacemark` objects containing coordinates, locality name, and country.

### When It Is Used

CLGeocoder is the **fallback** geocoder. It is triggered when:

1. **App launch:** `LocationService.init()` geocodes the saved city from `SettingMan.config.city`.
2. **Manual text input:** User types a city name in settings and closes without selecting a search result (`SettingsView.swift:190`).

### When It Is NOT Used

When the user selects a city from the Photon search dropdown, coordinates are passed directly (`SettingsView.swift:188`). CLGeocoder is bypassed entirely.

### Data Extracted from Placemarks

| Field               | Source                        |
|---------------------|-------------------------------|
| `latitude`          | `placemark.location.coordinate.latitude` |
| `longitude`         | `placemark.location.coordinate.longitude` |
| `locationName`      | `placemark.locality` (falls back to input) |
| `country`           | `placemark.country` (falls back to empty) |

### Error Handling

Geocoding failures (no results, network error) are caught and logged. Location state remains unchanged.

---

## 4. LocalLLMClient / Foundation Models

On-device AI chat assistant. No network calls — all inference runs locally.

**Source file:** `SunnyService.swift`

### Dependencies

| Package                              | Purpose                        |
|--------------------------------------|--------------------------------|
| `LocalLLMClient`                     | Swift wrapper for local LLMs   |
| `LocalLLMClientFoundationModels`     | Apple Foundation Models bridge |
| `FoundationModels` (Apple framework) | On-device LLM inference        |
| `MLX Swift` (transitive)             | Apple ML framework             |
| `swift-transformers` (transitive)    | Model loading utilities        |

### Platform Requirement

```swift
@available(macOS 26.0, *)   // macOS Tahoe or later
```

The entire `SunnyService` class and `SunnyView` UI are gated behind this availability check. On macOS 14–25, the AI feature is unavailable but the rest of the app functions normally.

### Model Configuration

```swift
LLMSession(model: .foundationModels(
    model: .default,
    parameter: .init(temperature: 0.7)
))
```

- **Model:** Apple Foundation Models default on-device model
- **Temperature:** 0.7 (balanced creativity/consistency)

### System Prompt

The LLM is initialized with a detailed system prompt defining "Sunny" as a friendly, concise AI companion. Key constraints:

- Responds in English only
- 1–3 sentence responses by default
- No bullet points, lists, or structured formatting
- Can access current weather context (temperature, condition, humidity, wind, UV index)
- Provides outfit, outdoor activity, and lifestyle recommendations based on weather

### Weather Context Injection

Each conversation turn includes a system message with current weather data:

```
Current conditions: Location: Catania, Temperature: 22°C, Condition: Sunny, Humidity: 65%, Wind: 12 km/h, UV Index: 6
```

This is appended to the session messages before each `respond(to:)` call.

### Session Management

- **Lazy initialization:** `LLMSession` is created on first message sent.
- **Clear history:** `clearHistory()` resets messages and creates a new session.
- **Isolation:** Entire class is `@MainActor`-isolated.

### Error Handling

LLM response failures are caught and replaced with a fallback message: *"Sorry, I couldn't process that right now."*

---

## 5. Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        App Launch                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │     SettingMan      │  Reads saved city from
              │   (config.json)     │  Application Support
              └────────┬────────────┘
                       │
            ┌──────────┴──────────┐
            │                     │
            ▼                     ▼
  ┌──────────────────┐  ┌──────────────────────┐
  │  CLGeocoder      │  │  Photon API          │
  │  (fallback)      │  │  (city search)       │
  │                  │  │  photon.komoot.io    │
  └────────┬─────────┘  └──────────┬───────────┘
           │                       │
           └───────────┬───────────┘
                       │
                       ▼
           ┌─────────────────────┐
           │   LocationService   │  @Published lat/lon
           │   (coordinates)     │
           └────────┬────────────┘
                    │  Combine pipeline
                    ▼
           ┌─────────────────────┐
           │   WeatherService    │  GET api.open-meteo.com
           │   (fetch + timer)   │  Auto-refresh every 5 min
           └────────┬────────────┘
                    │  @Published WeatherData
                    ▼
           ┌─────────────────────┐
           │    WeatherCard      │  Renders temperature,
           │    (UI)             │  condition, stats
           └────────┬────────────┘
                    │
                    ▼
           ┌─────────────────────┐
           │    SunnyService     │  On-device LLM
           │    (AI chat)        │  Weather context injected
           └─────────────────────┘
```

---

## 6. WMO Weather Code Mapping

Open-Meteo returns WMO (World Meteorological Organization) numeric weather codes. The app maps these to five visual conditions via `WeatherCondition.from(wmoCode:)`.

**Source file:** `WeatherConditionMapping.swift`

| WMO Code(s)         | App Condition | Description                          |
|----------------------|---------------|--------------------------------------|
| `0`                  | `.sunny`      | Clear sky                            |
| `1, 2, 3, 45, 48`   | `.cloudy`     | Mainly clear, partly cloudy, overcast, fog, rime fog |
| `51, 53, 55, 61, 63, 65, 80, 81, 82` | `.rainy` | Drizzle, rain, rain showers |
| `71, 73, 75, 77, 85, 86` | `.snowy` | Snowfall, snow showers |
| `95, 96, 99`        | `.stormy`     | Thunderstorm, thunderstorm with hail  |
| All other codes      | `.cloudy`     | Default fallback                     |

Each condition drives the app's visual theme — gradient backgrounds, text colors, and panel colors are all derived from the `WeatherCondition` enum.
