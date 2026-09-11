# Mock API layer

Until Django REST endpoints exist, the Flutter app talks to **local JSON** through the same `ApiClient` paths that production will use.

## How it works

1. Repositories always call `ApiClient` (`GET` / `POST` on paths in `lib/core/network/api_paths.dart`).
2. When `USE_MOCK_API=true` (default in `env/.env.*`), `MockApiInterceptor` serves `assets/data/*.json` and in-memory write handlers.
3. Set `USE_MOCK_API=false` and point `API_BASE_URL` at Django when DRF is ready — **screens and repository method signatures stay the same**.

## Env

```
USE_MOCK_API=true
API_BASE_URL=https://api-dev.example.com
```

## Path map

| Method | Path | Mock source |
|--------|------|-------------|
| GET | `/about` | `assets/data/about.json` |
| GET | `/api/v1/conditions` | `assets/data/conditions.json` (list shape) |
| GET | `/api/v1/conditions/{slug}` | item from conditions list |
| GET | `/services` | `assets/data/services.json` |
| GET | `/services/{id}` | item from services list |
| GET | `/blog` | `assets/data/blog.json` |
| GET | `/blog/{id}` | item from articles list |
| GET | `/faq` | `assets/data/faq.json` |
| GET | `/clinic` | `assets/data/clinic.json` |
| GET | `/api/v1/home` | `assets/data/home.json` |
| GET | `/patients` | `assets/data/patients.json` |
| GET | `/chatbot/config` | suggestions/disclaimer from `chatbot_replies.json` |
| POST | `/chatbot/message` | keyword replies from `chatbot_replies.json` |
| GET | `/appointments/availability` | generated from `appointment_config.json` |
| GET | `/appointments/slots` | generated from `appointment_config.json` |
| POST | `/appointments` | in-memory confirmation |
| POST | `/contact` | in-memory received id |

## Django slug alignment

Service and condition IDs in JSON match Django CMS slugs (e.g. `frequency-specific-microcurrent`, `toxins`). Membership remains excluded from the mobile app.

## QA hooks

- Contact / chatbot: put `force error` in the message (or contact subject) to simulate failure.
- Appointment: patient notes `force error` simulates a 409 slot conflict.
- Fridays return no appointment slots (empty-state testing).
