/// Contract for `GET /api/v1/memberships/`.
///
/// Response shape:
/// ```json
/// {
///   "title": "...",
///   "content": "...",
///   "plans": [{
///     "id": 7,
///     "title": "...",
///     "description": "...",
///     "heroImage": "...",
///     "benefits": ["..."],
///     "button-label": "Join Now",
///     "button-url": "https://buy.stripe.com/..."
///   }],
///   "reviews": [{ "name", "comment", "star", "date", "img-url" }]
/// }
/// ```
library;
