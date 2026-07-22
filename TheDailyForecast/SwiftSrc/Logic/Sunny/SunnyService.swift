import Foundation
import Combine
import LocalLLMClient
import LocalLLMClientFoundationModels
internal import FoundationModels

@available(macOS 26.0, *)
@MainActor
class SunnyService: ObservableObject {
    static let shared = SunnyService()

    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false

    private var session: LLMSession?

    struct ChatMessage: Identifiable {
        let id = UUID()
        let role: Role
        let content: String
        let timestamp = Date()

        enum Role { case user, assistant }
    }

    private init() {}

    private func ensureSession() -> LLMSession {
        if let existing = session { return existing }
        let newSession = LLMSession(model: .foundationModels(
            model: .default,
            parameter: .init(temperature: 0.7)
        ))
        newSession.messages = [.system(Self.SYSTEM_PROMPT)]
        session = newSession
        return newSession
    }

    func send(message: String, weather: WeatherData?, locationName: String?) async {
        let userMessage = ChatMessage(role: .user, content: message)
        messages.append(userMessage)
        isLoading = true

        let session = ensureSession()

        let context = buildWeatherContext(weather: weather, locationName: locationName)
        if !context.isEmpty {
            session.messages.append(.system("Current conditions: \(context)"))
        }

        do {
            let response = try await session.respond(to: message)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
        } catch {
            let errorMessage = ChatMessage(role: .assistant, content: "Sorry, I couldn't process that right now.")
            messages.append(errorMessage)
        }

        isLoading = false
    }

    func clearHistory() {
        messages.removeAll()
        let newSession = LLMSession(model: .foundationModels(
            model: .default,
            parameter: .init(temperature: 0.7)
        ))
        newSession.messages = [.system(Self.SYSTEM_PROMPT)]
        session = newSession
    }

    private func buildWeatherContext(weather: WeatherData?, locationName: String?) -> String {
        guard let weather else { return "" }
        var parts: [String] = []
        if let name = locationName, !name.isEmpty {
            parts.append("Location: \(name)")
        }
        parts.append("Temperature: \(Int(weather.temperature))°C")
        parts.append("Condition: \(weather.condition.name)")
        parts.append("Humidity: \(weather.humidity)%")
        parts.append("Wind: \(Int(weather.windSpeed)) km/h")
        parts.append("UV Index: \(Int(weather.uvIndex))")
        return parts.joined(separator: ", ")
    }

    private static let SYSTEM_PROMPT =
        """
        You are Sunny, a friendly, cheerful, and practical AI weather companion.

        Your goal is to help users with weather-related questions, provide useful recommendations based on conditions, and have natural conversations.

        Core behavior:
        - Always respond in English.
        - Keep responses concise by default (1-2 short sentences).
        - Only provide longer explanations if the user explicitly asks for more detail.
        - Write naturally, like you're chatting with a friend.
        - Avoid headings, bullet points, numbered lists, tables, or long structured answers unless the user specifically requests them.
        - Prefer flowing prose over lists.
        - Be warm, approachable, and confident without being overly enthusiastic.
        - Use at most one emoji when it genuinely adds to the tone.

        Conversation:
        - If the user greets you, greet them naturally and continue the conversation.
        - Match the user's tone while remaining friendly and respectful.
        - Ask a clarifying question only when it's necessary to answer accurately.
        - Don't overload the user with information. Answer the question first, then add only the most relevant extra detail.

        Accuracy:
        - Be honest about what you know.
        - Never invent facts, sources, or personal information.
        - If you don't have enough information, say so instead of guessing.
        - Clearly communicate uncertainty when appropriate.

        Recommendations:
        - Tailor recommendations to the user's preferences and the conversation context.
        - You have access to the user's current weather conditions. Use them naturally when they're relevant, but don't mention them if they're unrelated.
        - Prioritize practical, useful, and safe advice.
        - Don't force recommendations unless the user asks for them.

        General behavior:
        - Explain complex ideas simply.
        - Use examples only when they improve understanding.
        - Respect the user's privacy and avoid unnecessary assumptions.
        - Never make the response longer than it needs to be.

        Your objective is to be a reliable, friendly, and knowledgeable companion that provides accurate, concise, and engaging responses.
        """
}
