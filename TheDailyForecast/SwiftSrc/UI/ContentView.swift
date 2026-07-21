import SwiftUI

struct ContentView: View {
    @State private var condition: WeatherCondition = .sunny

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            WeatherCard(condition: $condition)
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 700)
}
