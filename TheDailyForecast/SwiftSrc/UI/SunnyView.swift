import SwiftUI

@available(macOS 26.0, *)
struct SunnyView: View {
    let weatherData: WeatherData?
    let locationName: String?
    let condition: WeatherCondition
    var onDismiss: () -> Void

    @StateObject private var sunnyService = SunnyService.shared
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                header
                Divider().background(.white.opacity(0.15))
                messagesScrollView
                inputBar
            }
            .frame(width: 320, height: 550)
            .background {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    condition.panelColor.opacity(0.4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)
            .shadow(radius: 5)
        }
        .frame(width: 800, height: 600)
        
        .onAppear {
            isInputFocused = true
        }
    }

    private var header: some View {
        HStack {
            Text("Sunny")
                .font(.custom("Lastik", size: 16))
                .foregroundStyle(.white)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.white.opacity(0.1)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if sunnyService.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(sunnyService.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                    }
                    if sunnyService.isLoading {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .onChange(of: sunnyService.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    if sunnyService.isLoading {
                        proxy.scrollTo("typing", anchor: .bottom)
                    } else if let last = sunnyService.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: sunnyService.isLoading) { _, loading in
                if loading {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 28))
                .foregroundStyle(.yellow.opacity(0.6))
            Text("Hi! I'm Sunny.\nAsk me anything about the weather.")
                .font(.custom("JetBrainsMono-Regular", size: 12))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func messageBubble(_ message: SunnyService.ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            markdownText(message.content)
                .font(.custom("JetBrainsMono-Regular", size: 12))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(message.role == .user
                            ? AnyShapeStyle(.white.opacity(0.15))
                            : AnyShapeStyle(condition.panelColor.opacity(0.15)))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.08))
                }

            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private func markdownText(_ text: String) -> Text {
        let segments = parseBoldMarkdown(text)
        var result = Text("")
        for segment in segments {
            if segment.isBold {
                result = result + Text(segment.text).bold()
            } else {
                result = result + Text(segment.text)
            }
        }
        return result
    }

    private func parseBoldMarkdown(_ text: String) -> [MarkdownSegment] {
        var segments: [MarkdownSegment] = []
        var remaining = text

        while let boldRange = remaining.range(of: "**") {
            let before = String(remaining[remaining.startIndex..<boldRange.lowerBound])
            if !before.isEmpty {
                segments.append(MarkdownSegment(text: before, isBold: false))
            }

            let afterFirstBold = String(remaining[boldRange.upperBound...])
            if let endBoldRange = afterFirstBold.range(of: "**") {
                let boldText = String(afterFirstBold[afterFirstBold.startIndex..<endBoldRange.lowerBound])
                if !boldText.isEmpty {
                    segments.append(MarkdownSegment(text: boldText, isBold: true))
                }
                remaining = String(afterFirstBold[endBoldRange.upperBound...])
            } else {
                segments.append(MarkdownSegment(text: "**\(afterFirstBold)", isBold: false))
                remaining = ""
            }
        }

        if !remaining.isEmpty {
            segments.append(MarkdownSegment(text: remaining, isBold: false))
        }

        return segments
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask Sunny...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.custom("JetBrainsMono-Regular", size: 12))
                .foregroundStyle(.white)
                .focused($isInputFocused)
                .onSubmit { sendMessage() }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.2) : .white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.08) : .white.opacity(0.2)))
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || sunnyService.isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                condition.panelColor.opacity(0.2)
            }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !sunnyService.isLoading else { return }
        inputText = ""
        Task {
            await sunnyService.send(message: text, weather: weatherData, locationName: locationName)
        }
    }
}

@available(macOS 26.0, *)
private struct MarkdownSegment: Identifiable {
    let id = UUID()
    let text: String
    let isBold: Bool
}

@available(macOS 26.0, *)
private struct TypingIndicator: View {
    @State private var dotOffsets: [CGFloat] = [0, 0, 0]

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(.white.opacity(0.4))
                        .frame(width: 5, height: 5)
                        .offset(y: dotOffsets[i])
                        .animation(
                            .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                            value: dotOffsets[i]
                        )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(0.08))
            }
            Spacer()
        }
        .onAppear {
            dotOffsets = [-3, -3, -3]
        }
    }
}
