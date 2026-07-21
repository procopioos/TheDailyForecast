import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settingMan = SettingMan.shared
    @State private var searchText: String = ""
    @State private var searchResults: [CityResult] = []
    @State private var selectedCity: CityResult?
    @State private var selectedUnit: TemperatureUnit = .celsius
    @State private var searchTask: Task<Void, Never>?
    @State private var isSelecting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings")
                .font(.custom("JetBrainsMono-Regular", size: 16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)

            Divider()
                .background(.white.opacity(0.2))

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("City")
                        .font(.custom("JetBrainsMono-Regular", size: 12))
                        .foregroundStyle(.white.opacity(0.7))

                    ZStack(alignment: .topLeading) {
                        TextField("Search city (in English)...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.custom("JetBrainsMono-Regular", size: 14))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.white.opacity(0.15))
                            }
                            .onChange(of: searchText) { _, newValue in
                                guard !isSelecting else {
                                    isSelecting = false
                                    return
                                }
                                onSearchTextChanged(newValue)
                            }

                        if !searchResults.isEmpty {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(searchResults) { city in
                                        Button {
                                            selectCity(city)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(city.name)
                                                        .font(.custom("JetBrainsMono-Regular", size: 13))
                                                        .foregroundStyle(.white)
                                                    Text(city.displayName)
                                                        .font(.custom("JetBrainsMono-Regular", size: 10))
                                                        .foregroundStyle(.white.opacity(0.5))
                                                }
                                                Spacer()
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)

                                        if city.id != searchResults.last?.id {
                                            Divider()
                                                .background(.white.opacity(0.1))
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                            .background {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.black.opacity(0.85))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            }
                            .padding(.top, 34)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Temperature Unit")
                        .font(.custom("JetBrainsMono-Regular", size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                    Picker("", selection: $selectedUnit) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                            Text(unit.symbol).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedUnit) { _, newUnit in
                        settingMan.config.temperatureUnit = newUnit
                    }
                }
            }
            .padding(18)

            Spacer()

            HStack {
                Button {
                    settingMan.resetToDefaults()
                    isSelecting = true
                    searchText = settingMan.config.city
                    selectedCity = nil
                    selectedUnit = settingMan.config.temperatureUnit
                    searchResults = []
                    applyChanges()
                } label: {
                    Text("Reset")
                        .font(.custom("JetBrainsMono-Regular", size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    applyChanges()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .frame(width: 400, height: 350)
        .onAppear {
            isSelecting = true
            searchText = settingMan.config.city
            selectedUnit = settingMan.config.temperatureUnit
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    private func onSearchTextChanged(_ query: String) {
        searchTask?.cancel()
        selectedCity = nil

        guard query.count >= 3 else {
            searchResults = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            searchResults = await CitySearchService.shared.search(query: query)
        }
    }

    private func selectCity(_ city: CityResult) {
        selectedCity = city
        isSelecting = true
        searchText = city.displayName
        searchResults = []
        applyChanges()
    }

    private func applyChanges() {
        let name = selectedCity?.name ?? searchText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        if let city = selectedCity {
            settingMan.config.city = city.displayName
        } else {
            settingMan.config.city = name
        }
        Task {
            if let city = selectedCity {
                await WeatherService.shared.updateLocation(city.name, latitude: city.latitude, longitude: city.longitude, country: city.country)
            } else {
                await WeatherService.shared.updateLocation(name)
            }
        }
    }
}

#Preview {
    SettingsView()
}
