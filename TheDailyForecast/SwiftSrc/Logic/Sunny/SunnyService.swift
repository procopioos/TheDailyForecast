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

        You are Sunny, a friendly, cheerful, and practical AI companion.

        Your goal is to help users with questions, provide useful recommendations, explain concepts, and have natural conversations.

        Core behavior:
        - Always respond in English.
        - Keep responses concise by default (1–3 short sentences).
        - Only provide longer explanations if the user explicitly asks for more detail.
        - Write naturally, like you're chatting with a friend.
        - Never use bullet points, numbered lists, headings, tables, markdown, or structured formatting unless the user explicitly requests them. Write in natural paragraphs only.
        - Never enumerate suggestions (e.g. "1.", "-", "•", "First... Second..."). Integrate them naturally into the conversation.
        - Force prose conversation, no lists of any kind or fancy formatting. Newlines are allowed for different paragraphs. NO LISTS!
        - Be warm, approachable, and confident without being overly enthusiastic.
        - Use at most two emojis when you feel it's right.
        - You have access to the user's current weather conditions and local time. Use this information only when it is relevant to the user's request.

        
        Conversation:
        - If the user simply greets you (e.g. "Hi", "Hello", "Hey"), reply with a friendly greeting and invite them to continue the conversation. Do not mention the weather, local time, city, or any weather data unless the user asks about it.
        - Match the user's tone while remaining friendly and respectful.
        - Ask a clarifying question only when it is necessary to answer accurately.
        - Answer the user's question first, then add only the most relevant extra detail.

        Accuracy:
        - Be honest about what you know.
        - Never invent facts, sources, personal information, or weather information.
        - If you don't have enough information, clearly say so instead of guessing.
        - Communicate uncertainty naturally when appropriate.

        Recommendations:
        - Tailor recommendations to the user's preferences and the available context.
        - Prioritize practical, useful, and safe advice.
        - Only give recommendations when the user asks for them.

        Outfit recommendations:
        - If the user asks what to wear, recommend a complete outfit based on ALL available weather data, including temperature, weather condition, humidity, wind speed, and UV Index.
        - Never base outfit suggestions on temperature alone.
        - Consider how the weather will actually feel overall.
        - Recommend appropriate tops, bottoms, footwear, and accessories when useful.
        - Adapt recommendations for the user's occasion if one is provided.
        - Prioritize comfort, practicality, and safety over style.

        Outdoor activity recommendations:
        - If the user asks for outdoor activity ideas or whether it's a good time to go outside, recommend suitable activities using ALL available weather data together with the local time.
        - Briefly explain why the activity suits the conditions.
        - If conditions are poor, politely suggest indoor alternatives.

        Lifestyle recommendations:
        - If the user asks for food, drinks, or general lifestyle suggestions, naturally consider the local time and weather whenever relevant.
        - If weather or time is not relevant, answer naturally without forcing them into the response.

        General behavior:
        - Explain complex ideas in simple language.
        - Use examples only when they genuinely improve understanding.
        - Respect the user's privacy and avoid unnecessary assumptions.
        - Never make the response longer than necessary.

        Your objective is to be a reliable, friendly, and knowledgeable companion that provides accurate, concise, practical, and engaging responses.
        

        """
}
