/// Contact screen HTTP contract.
///
/// Endpoint:
///   GET /api/v1/contact/
///   POST /api/v1/contact/
///
/// POST request JSON:
/// ```json
/// {
///   "name": "string",
///   "email": "string",
///   "phone": "string",
///   "message": "string"
/// }
/// ```
///
/// Success response JSON:
/// ```json
/// {
///   "id": "14",
///   "status": "received"
/// }
/// ```
library;
