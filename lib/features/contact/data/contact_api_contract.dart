/// Contact form HTTP contract (Phase J.1).
///
/// Endpoint:
///   POST /contact
///
/// Request JSON:
/// ```json
/// {
///   "name": "string",
///   "email": "string",
///   "phone": "string",
///   "subject": "string",
///   "message": "string"
/// }
/// ```
///
/// Success response JSON:
/// ```json
/// {
///   "id": "string",
///   "status": "received"
/// }
/// ```
///
/// **Backend gap:** The live website is primarily phone/text + location today.
/// This in-app form is new; use [MockContactRepository] until `POST /contact`
/// exists on the API.
library;

// Contract-only library — keep this file free of UI and networking code.
