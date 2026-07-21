import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settingMan = SettingMan.shared
    @State private var cityInput: String = ""
    @State private var selectedUnit: TemperatureUnit = .celsius

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
                    TextField("Enter city name", text: $cityInput)
                        .textFieldStyle(.plain)
                        .font(.custom("JetBrainsMono-Regular", size: 14))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.15))
                        }
                        .onSubmit { applyChanges() }
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
                    cityInput = settingMan.config.city
                    selectedUnit = settingMan.config.temperatureUnit
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
        .frame(width: 400, height: 300)
        .onAppear {
            cityInput = settingMan.config.city
            selectedUnit = settingMan.config.temperatureUnit
        }
    }

    private func applyChanges() {
        let trimmed = cityInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        settingMan.config.city = trimmed
        Task {
            await WeatherService.shared.updateLocation(trimmed)
        }
    }
}

#Preview {
    SettingsView()
}
