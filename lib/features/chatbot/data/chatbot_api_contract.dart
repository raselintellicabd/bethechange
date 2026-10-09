/// Website assistant HTTP contract (same answers as the site chat widget).
///
/// Endpoint (no auth):
///   POST /api/v1/chatbot/ask/
///
/// Request JSON:
/// ```json
/// {
///   "message": "string",
///   "history": [{"role": "user|assistant", "content": "string"}]
/// }
/// ```
///
/// Success response JSON:
/// ```json
/// {
///   "reply": "string",
///   "links": [{"title": "string", "url": "/site-relative/", "kind": "string"}],
///   "handoff": false,
///   "source": "rule|search|ai"
/// }
/// ```
///
/// `handoff: true` means the visitor asked for a person: open live chat.
/// 429 `{"error": "..."}` when the visitor asks too quickly.
library;

// Contract-only library — keep this file free of UI and networking code.
