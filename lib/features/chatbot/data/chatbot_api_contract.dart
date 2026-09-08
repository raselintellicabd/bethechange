/// Chatbot HTTP contract (Phase I.3).
///
/// Endpoint:
///   POST /chatbot/message
///
/// Auth:
///   Send `CHATBOT_API_KEY` from env as `X-Api-Key` (or Bearer when the
///   backend standardizes). Loaded via [EnvConfig.chatbotApiKey].
///
/// Request JSON:
/// ```json
/// {
///   "message": "string",
///   "conversationId": "string?" // omit or null to start a new conversation
/// }
/// ```
///
/// Success response JSON:
/// ```json
/// {
///   "reply": "string",
///   "conversationId": "string"
/// }
/// ```
///
/// The mock repository implements this shape until the real API is ready.
library;

// Contract-only library — keep this file free of UI and networking code.
