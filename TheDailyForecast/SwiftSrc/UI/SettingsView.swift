import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var btnTxt = "Nothing to see here :)"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings")
                .font(.custom("JetBrainsMono-Regular", size: 16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)

            Divider()
                .background(.white.opacity(0.2))

            Button {
                btnTxt = "Boop!"
            } label: {
                Text(btnTxt)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 18)
        }
        .frame(width: 400, height: 300)
    }
}

#Preview {
    SettingsView()
}
