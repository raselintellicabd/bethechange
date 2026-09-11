/// Contact form HTTP contract.
///
/// Endpoint:
///   POST /api/v1/contact-messages/
///
/// Request JSON:
/// ```json
/// {
///   "name": "string",
///   "email": "string",
///   "phone": "string",
///   "message": "string",
///   "is_read": false
/// }
/// ```
///
/// Success response JSON:
/// ```json
/// {
///   "id": 12,
///   "name": "string",
///   "email": "string",
///   "phone": "string",
///   "message": "string",
///   "is_read": false,
///   "created_at": "2026-09-11T06:54:04.655004Z",
///   "conversation": 3
/// }
/// ```
library;

// Contract-only library — keep this file free of UI and networking code.
