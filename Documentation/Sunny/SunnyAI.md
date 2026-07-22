# Sunny AI

On-device AI chat assistant built into The Daily Forecast.

---

## Overview

Sunny is a conversational AI companion that runs entirely on-device. It can answer questions about the current weather, recommend outfits, suggest outdoor activities, and provide lifestyle advice — all based on live weather data without sending anything to external servers.

- **Platform:** macOS 26.0+ (Tahoe) only. The feature is unavailable on macOS 14–25.
- **Inference:** Fully local via Apple Foundation Models. No network calls.
- **Source files:** `SunnyService.swift` (logic), `SunnyView.swift` (UI)

---

## Architecture

```
SunnyView (SwiftUI)
    │
    │  @StateObject
    ▼
SunnyService (ObservableObject, singleton)
    │
    │  LLMSession
    ▼
Apple Foundation Models (on-device)
```

- **SunnyService** holds the chat state (`messages`, `isLoading`) and manages the LLM session. It is a singleton (`static let shared`) and fully `@MainActor`-isolated.
- **SunnyView** is a SwiftUI panel that observes the service and renders messages, input, and loading states.
- Weather data (`WeatherData` + `locationName`) is passed into the service on each send, not stored.

---

## Dependencies

| Package                              | Purpose                        |
|--------------------------------------|--------------------------------|
| `LocalLLMClient`                     | Swift wrapper for local LLMs   |
| `LocalLLMClientFoundationModels`     | Apple Foundation Models bridge |
| `FoundationModels` (Apple framework) | On-device LLM inference        |
| `MLX Swift` (transitive)             | Apple ML framework             |
| `swift-transformers` (transitive)    | Model loading utilities        |
| `swift-huggingface` (transitive)     | Hub integration                |

The entire feature is gated behind `@available(macOS 26.0, *)`. On older systems, both the service class and the view are inaccessible, and the app functions without AI.

---

## LLM Configuration

```swift
LLMSession(model: .foundationModels(
    model: .default,
    parameter: .init(temperature: 0.7)
))
```

- **Model:** Apple's default on-device Foundation Model.
- **Temperature:** 0.7 — balances creativity with consistency.
- **Session lifecycle:**
  - **Lazy init:** The `LLMSession` is created on the first call to `send()`, not at service init.
  - **Clear history:** `clearHistory()` discards all messages and creates a fresh session with a new system prompt. Called from the UI to reset the conversation.

---

## Behavioral Rules

Sunny is configured with a system prompt that defines its personality and constraints. Key behavioral rules:

- **Personality:** Friendly, cheerful, practical. Chat-like tone, not robotic.
- **Conciseness:** 1–3 sentences by default. Longer only when explicitly asked.
- **No structured output:** No bullet points, numbered lists, headings, or markdown. Natural prose only.
- **Language:** English only.
- **Emoji:** At most two, used sparingly.
- **Weather awareness:** Has access to current weather data. Uses it when relevant, never forces it into unrelated answers.
- **Recommendation domains:**
  - **Outfit:** Considers all weather data (temperature, condition, humidity, wind, UV), not just temperature. Adapts to occasion.
  - **Outdoor activities:** Uses weather + local time. Suggests indoor alternatives when conditions are poor.
  - **Lifestyle (food, drinks):** Considers time and weather only when relevant.
- **Honesty:** Never invents facts. Communicates uncertainty naturally.

---

## Weather Context Injection

On every user message, Sunny receives a system-level context string with the current weather. This is appended to the LLM session before the model responds.

### Included Fields

| Field         | Example              |
|---------------|----------------------|
| Location      | `Catania`            |
| Temperature   | `22°C`               |
| Condition     | `Sunny`              |
| Humidity      | `65%`                |
| Wind          | `12 km/h`            |
| UV Index      | `6`                  |

### Format

```
Current conditions: Location: Catania, Temperature: 22°C, Condition: Sunny, Humidity: 65%, Wind: 12 km/h, UV Index: 6
```

### Behavior

- Context is injected as a **system message** per turn, not as part of the conversation history.
- If `WeatherData` is nil, no context is injected — Sunny still responds, just without weather awareness.
- Context is rebuilt from scratch each turn, always reflecting the latest weather data.

---

## Message Flow

```
User types message + taps send
        │
        ▼
SunnyView.sendMessage()
  - Trims whitespace, validates non-empty + not loading
  - Clears input field
        │
        ▼
SunnyService.send(message:weather:locationName:)
  - Appends user ChatMessage to messages[]
  - Sets isLoading = true
  - Builds weather context string
  - Appends context as system message to LLMSession
        │
        ▼
LLMSession.respond(to: message)
  - On-device inference
  - Returns response string
        │
        ▼
SunnyService
  - Appends assistant ChatMessage to messages[]
  - Sets isLoading = false
  - UI auto-scrolls to latest message
```

### Error Path

If `LLMSession.respond()` throws:
- A fallback assistant message is appended: *"Sorry, I couldn't process that right now."*
- `isLoading` is set to `false`.
- No retry is attempted.

---

## Visual Integration

The Sunny panel adapts its appearance to the current weather condition.

- **Panel background:** `condition.panelColor` layered over `.ultraThinMaterial`.
- **Message bubbles:**
  - User messages: white with low opacity.
  - Assistant messages: `condition.panelColor` with low opacity.
- **Input bar:** Tinted with `condition.panelColor`.
- **Empty state:** Sun icon with a greeting prompt.
- **Typing indicator:** Three bouncing dots with staggered animation (0.4s ease-in-out, 0.15s delay between dots).
- **Auto-scroll:** Scrolls to the latest message or typing indicator on new content or loading state changes.

---

## Error Handling

| Scenario                    | Behavior                                        |
|-----------------------------|------------------------------------------------|
| LLM inference fails         | Fallback message appended, loading cleared      |
| Input is empty or whitespace| Send blocked (button disabled)                  |
| Already loading             | Send blocked (button disabled)                  |
| Clear history called        | Messages wiped, new session created             |
