/// Contact screen HTTP contract.
///
/// Endpoint:
///   GET /api/v1/contact/
///   POST /api/v1/contact/
///
/// GET `form` includes `category` / `doctor_id` fields and `doctors`.
///
/// POST request JSON (Services):
/// ```json
/// {
///   "name": "string",
///   "email": "string",
///   "phone": "string",
///   "category": "services",
///   "message": "string"
/// }
/// ```
///
/// POST request JSON (Doctors):
/// ```json
/// {
///   "name": "string",
///   "email": "string",
///   "phone": "string",
///   "category": "doctors",
///   "doctor_id": 1,
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
