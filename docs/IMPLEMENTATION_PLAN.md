# BeTheChange Flutter App — Implementation Plan

**Reference website:** [https://www.bethechangewellnesscenter.com/](https://www.bethechangewellnesscenter.com/)  
**Repo:** `BeTheChange`  
**Last updated:** 2026-09-03  

This is the working build guide for migrating the website into a Flutter mobile app. It is derived from the original Website → Flutter Implementation Flow, reorganized around what already exists in this repo, what the live site actually contains, and the order that avoids rework.

---

## How to use this document

1. Work **top to bottom**. Do not start a feature phase before its prerequisites are done.
2. When starting a new AI session, paste:
   - **Global Conventions** (below)
   - Only the **next incomplete step** (or a small group of tightly related steps)
   - Any open decisions that block that step
3. After each step, update the **Status** column in the progress table.
4. Prefer **shipping working UI with local JSON first**, then swap repositories to API later without rewriting screens.

---

## Global Conventions (paste into every session)

| Rule | Detail |
|------|--------|
| Framework | Flutter (latest stable), Dart null-safety |
| State | Riverpod (`flutter_riverpod`) |
| Navigation | `go_router` (declarative + deep links) |
| Networking | `dio` + interceptors (auth/logging) |
| Structure | Feature-first: `lib/features/<feature>/{data,domain,presentation}` |
| Design tokens | All colors/fonts/spacing in `lib/core/theme/` — **no hardcoded hex in widgets** |
| Naming | Screens end in `Screen`; reusable widgets end in `Widget` or descriptive nouns |
| **Excluded** | **No Membership feature anywhere** |
| **Appointment rule** | **No direct/deep-link entry to Appointment.** Always require `sourceContext` (see Phase C / appointment contract) |
| Brand / UI | Mobile UI should feel consistent with the website — **especially color**. Inspect live site CSS/brand assets and replace placeholder theme tokens before polishing feature UIs |
| Run flavors | `flutter run --flavor dev -t lib/main_dev.dart` (also `staging` / `prod`) |

---

## Current foundation (already done)

Phase 0 + Phase 1 from the original plan are **complete** in this repo:

| Area | Location / notes |
|------|------------------|
| Dependencies | `pubspec.yaml` — go_router, riverpod, dio, cached_network_image, flutter_svg, intl, table_calendar, flutter_dotenv, shared_preferences |
| Env + flavors | `env/.env.{dev,staging,prod}`, Android product flavors, iOS schemes `dev` / `staging` / `prod` |
| Entry points | `lib/main.dart`, `main_dev.dart`, `main_staging.dart`, `main_prod.dart`, `lib/app.dart` |
| Feature folders | `lib/features/{about,conditions,services,blog,patient,faq,contact,appointment}/` |
| Network | `lib/core/network/` — `ApiClient`, `ApiResult`, `ApiException` |
| Theme (placeholder) | `lib/core/theme/` — **must be updated to match website colors** |
| Router skeleton | `lib/core/router/` — 5-tab shell + nested routes + appointment `sourceContext` guard |
| Stub widgets | `lib/core/widgets/` — AppButton, AppCard, SectionHeader, ImageWithCaption, ReviewCard, DoctorProfileCard, LoadingIndicator, ErrorStateWidget, EmptyStateWidget |

**Verified:** `flutter analyze` clean; widget test passes; Android `dev` debug APK builds.

**Not verified on this machine:** iOS simulator run (Windows host). Verify on macOS before release phases.

---

## Progress tracker

| Phase | Name | Status |
|-------|------|--------|
| A | Brand tokens + content strategy lock | 🟨 A.2 + A.3 done; A.1 pending |
| B | About tab | ✅ Done |
| C | Shared content models + Appointment contract | ✅ Done |
| D | Conditions tab | ✅ Done |
| E | Services tab | ✅ Done |
| F | Appointment booking flow | ✅ Done |
| G | Blog tab | ✅ Done |
| H | Patient tab (3 cards only) | ✅ Done |
| I | FAQ + Chatbot | ✅ Done |
| J | Contact form | ✅ Done |
| K | Cross-cutting (a11y, deep links, analytics) | ✅ Done |
| L | Final QA + store release | ⬜ Not started |

Legend: ⬜ Not started · 🟨 In progress · ✅ Done · ⏸ Blocked

---

## Recommended content strategy (default until CMS is ready)

Until a CMS/API is confirmed, ship **bundled JSON + local/remote images**:

```
assets/
  data/
    about.json
    conditions.json
    services.json
    blog.json
    faq.json
  images/          # only if we host optimized local copies
```

Each feature gets:

- `domain/models/` — pure Dart models + `fromJson`
- `data/<feature>_repository.dart` — reads assets (later: Dio)
- `presentation/` — Riverpod providers + screens/widgets

When backend exists, swap only the repository implementation. Screens stay the same.

---

## Website inventory (scraped for planning)

### About (4 content areas)

| Subtab | Website source |
|--------|----------------|
| Our Practice | `/about/` — practice copy, vision, goal, core values |
| Integrative Medicine | linked from About / dedicated pages |
| Naturopathic Medicine | linked from About / dedicated pages |
| Our Process | `/our-process/` — multi-step process + therapy overview |

Doctors on site: **Sultana Afrooz, D.O.** · **Jessica Needle, N.D.**  
Patient reviews appear on About / Home / Services (Google-style review block).

### Conditions (8)

Use these **stable IDs** in routes and JSON:

| ID | Name |
|----|------|
| `diabetes` | Diabetes |
| `obesity` | Obesity |
| `heart-disease` | Heart Disease |
| `chronic-fatigue` | Chronic Fatigue |
| `chronic-pain` | Chronic Pain |
| `hormone-imbalance` | Hormone Imbalance |
| `detoxification` | Detoxification (Toxins) |
| `concussion` | Concussion |

Route: `/conditions/:conditionId`

### Services (8 from `/services/`)

| ID | Name |
|----|------|
| `fsm` | Frequency Specific Microcurrent Therapy |
| `infrared-sauna` | Infrared Sauna Therapy |
| `hbot` | Hyperbaric Oxygen Therapy |
| `nutritional-iv` | Nutritional IV Therapy |
| `liquivida-iv` | LIQUIVIDA IV Therapy |
| `ozone` | Ozone Therapy |
| `reflexology` | Reflexology |
| `ion-foot-detox` | Ion Foot Detox |

Route: `/services/:serviceId`  
Note: Our Process also mentions Craniosacral Therapy / Essential Oils — include only if they appear as first-class service pages; otherwise keep under Process content.

### Patient tab external targets (from `/patients/`)

| Card | Target | App behavior |
|------|--------|--------------|
| Patient Portal | `https://be-the-change-portal.md-hq.com/` | External (url_launcher / WebView) |
| Book a Service | `https://live.vcita.com/site/8153u4j7n2974xi3/online-scheduling` | See open decisions — do **not** copy Membership |
| Shop Supplements | `https://us.fullscript.com//welcome/safrooz` | External |
| ~~Membership~~ | ~~site memberships page~~ | **DO NOT BUILD** |

### FAQ

Source: `/new-patient-questions/` — **label everywhere as FAQ**, never “New Patient Questions”.

### Contact

Website contact today is mostly **TEXT 301-970-9724** + location. In-app Contact form is a **new feature** (Phase J) and needs a backend contract.

### Clinic facts (for Contact / footer reuse)

- Address: 8808 Centre Park Drive, Suite 301, Columbia, MD 21045  
- Phone: 301-970-9724 · Fax: 301-359-1986  
- Hours: confirm Mon–Fri window (site pages disagree slightly: 9–6 vs 10–5) — **stakeholder confirm**

---

## Open decisions (block specific phases)

Resolve these with stakeholders; do not guess in production code:

| # | Decision | Blocks | Suggested default for development |
|---|----------|--------|-----------------------------------|
| 1 | Content source: static JSON vs CMS/API | All content phases | Static JSON now; repository interface ready for API |
| 2 | Brand colors/fonts from site (exact tokens) | Phase A polish | Inspect site CSS / logo assets; update `AppColors` |
| 3 | Patient Portal: in-app WebView vs external browser | Phase H | External browser via `url_launcher` |
| 4 | Shop Supplements: same | Phase H | External browser |
| 5 | “Book a Service” card: open Services tab vs generic appointment vs vcita URL | Phase H | Open Services list in-app; appointment only via CTA with `sourceContext` |
| 6 | Chatbot provider / history persistence | Phase I | Mock API first; session memory only |
| 7 | Contact form API exists? | Phase J | Mock repository until backend ready |
| 8 | Appointment API vs continue using vcita/Calendly-like web flow | Phase F | Native calendar UI + mock API; can wrap web booking as interim |

---

# Implementation phases (step-by-step)

---

## Phase A — Brand lock + shared content plumbing

**Goal:** Make the app look like BeTheChange and establish patterns every feature will copy.

### A.1 Extract and apply website design tokens

**Objective:** Replace placeholder theme with website-aligned colors (and fonts if licensed/bundled).

**Actions:**
1. Inspect live site (CSS / DevTools / logo assets) for primary, secondary, accent, backgrounds, text.
2. Update `lib/core/theme/app_colors.dart`, `app_text_styles.dart`, `app_spacing.dart`, `app_theme.dart`.
3. Keep **zero hex literals** outside `app_colors.dart`.
4. Optionally add a temporary Theme Preview screen to validate tokens.

**Files:** `lib/core/theme/*`  
**DoD:** Sample screen using `Theme.of(context)` matches website palette; no hardcoded colors in widgets.

### A.2 Asset pipeline + JSON loading utility

**Objective:** One way to load bundled content.

**Actions:**
1. Add `assets/data/` (and image dirs if needed) to `pubspec.yaml`.
2. Create `lib/core/utils/asset_loader.dart` (or similar) to load/decode JSON safely into `ApiResult` / typed models.
3. Add `flutter_test` parsing tests pattern for models.

**Files:** `pubspec.yaml`, `lib/core/utils/`, `assets/data/`  
**DoD:** A sample JSON file loads in a unit test without crashing.

### A.3 Shared `SourceContext` model (early)

**Objective:** Formalize appointment entry context before Conditions/Services CTAs.

**Actions:**
1. Create `lib/features/appointment/domain/models/source_context.dart`:
   - `type`: `condition | service | blog | other`
   - `id`: `String`
   - `name`: `String`
2. Encode/decode for query param (JSON or compact string) used by `AppRoutes.appointmentPath`.
3. Keep router redirect if missing/invalid.

**Files:** `lib/features/appointment/domain/models/source_context.dart`, `lib/core/router/app_router.dart`, `lib/core/router/app_routes.dart`  
**DoD:** Navigating to `/appointment` without context redirects away; with valid context, placeholder screen shows type/id/name.

---

## Phase B — About tab

**Prereq:** A.1 (tokens) strongly recommended; A.2 required for JSON.

### B.1 About models + local content

**Objective:** Model About content from the website.

**Actions:**
1. Scrape/copy About + Process (+ Integrative / Naturopathic pages).
2. Models: `AboutSection`, `DoctorProfile`, `Review` under `lib/features/about/domain/models/`.
3. Bundle `assets/data/about.json`.
4. Unit test: JSON → models.

**DoD:** Parsing test passes for all 4 sections + doctors + reviews.

### B.2 `AboutRepository` + Riverpod providers

**Objective:** Load About data once and cache in memory.

**Actions:**
1. `lib/features/about/data/about_repository.dart`
2. Providers for sections / doctors / reviews
3. Loading / error / data states using core widgets

**DoD:** Provider exposes data; forced bad JSON shows `ErrorStateWidget`.

### B.3 `AboutScreen` with 4 subtabs

**Objective:** Tab shell matching website About IA.

**Subtabs:** Our Practice · Naturopathic Medicine · Integrative Medicine · Our Process

**Actions:**
1. Build `about_screen.dart` with `TabBar` / `TabBarView` (preserve state with `AutomaticKeepAliveClientMixin` or `IndexedStack`).
2. Wire into router (replace About placeholder).

**DoD:** Switching tabs keeps state; no flicker; distinct content per tab.

### B.4 About content UI + doctors/reviews

**Objective:** Full scrollable content per subtab.

**Actions:**
1. `AboutContentView` for rich text/image blocks.
2. Flesh out `DoctorProfileCard` and `ReviewCard` in `lib/core/widgets/` to match site layout more closely.
3. Use `cached_network_image` for remote images; placeholders/errors via existing stubs.
4. Horizontal or vertical reviews list; empty state if none.

**DoD:** All 4 subtabs match website content structure on small + large phones.

### B.5 About QA

**Checklist:** copy accuracy · images · loading · offline/error · theme tokens only  
**DoD:** Side-by-side vs website; no missing sections.

---

## Phase C — Shared detail building blocks

**Goal:** Conditions and Services share layout patterns — extract once.

### C.1 Shared content section models (optional but recommended)

If Conditions and Services share shape, introduce a lightweight shared shape in `lib/core/` or a shared domain folder, e.g.:

- `ContentBlock` (title, body, imageUrl)
- `LabeledListItem` (label, iconUrl?, description)
- `RecommendedBook` (title, author, coverUrl, purchaseUrl?)

Avoid over-abstracting: only share what both features actually need.

### C.2 Shared presentation widgets

Extract when used twice:

- `BookCard`
- `BulletOrIconListSection`
- `AppointmentCtaBar` (button that pushes appointment with `SourceContext`)

Prefer feature widgets first; promote to `lib/core/widgets/` only when reused.

**DoD:** CTA helper builds a valid appointment route with encoded `SourceContext`.

---

## Phase D — Conditions tab

**Prereq:** A.2, A.3, Phase C CTA helper.

### D.1 Condition models + `conditions.json`

**Sections per condition (from original plan / site detail pages):**

1. Title + hero image  
2. Article body  
3. Common Symptoms  
4. Factors that Contribute  
5. Our Integrative Approach to {Name}  
6. Benefits of Integrative Medicine for {Name}  
7. Ways We Can Treat {Name}  
8. Recommended Books  

**Models:** `Condition`, `SymptomItem`, `TreatmentMethod`, `RecommendedBook`  
**IDs:** use the table in Website inventory.

**DoD:** All 8 parse in unit tests.

### D.2 `ConditionsListScreen`

- Grid/list of cards (name + image/icon)
- Tap → `/conditions/:conditionId`
- Replace router placeholder

**DoD:** All 8 listed and navigate with correct ID.

### D.3 `ConditionDetailScreen`

- Render all sections with `SectionHeader` + feature widgets
- Books as horizontal list
- Dynamic titles (“Our Integrative Approach to Diabetes”)

**DoD:** At least Diabetes + Heart Disease fully populated; others follow same template.

### D.4 Appointment CTA

- Prominent `AppButton`: “Request an Appointment”
- Navigate with `SourceContext(type: condition, id, name)`
- Place near top and/or bottom

**DoD:** From any condition, appointment placeholder shows correct context (no cross-condition leakage).

### D.5 Conditions QA

Walk all 8 · CTA context · scroll performance · theme compliance  
**DoD:** 8/8 signed off.

---

## Phase E — Services tab

**Structurally same as Conditions; reuse widgets.**

### E.1 Service models + `services.json`

Enumerate the 8 services from inventory. Confirm which detail sections exist per service page (may be shorter than conditions).

**DoD:** All services modeled and parsed.

### E.2 `ServicesListScreen` → `/services/:serviceId`

**DoD:** All services listed and navigable.

### E.3 `ServiceDetailScreen`

Reuse Conditions widgets where shape matches; adjust labels to service wording.

**DoD:** Detail matches website per service.

### E.4 Appointment CTA

`SourceContext(type: service, id, name)`  
**DoD:** Verified from every service detail.

### E.5 Services QA

**DoD:** Content + CTA signed off for all services.

---

## Phase F — Appointment booking flow

**Prereq:** A.3 working; at least one real CTA from Conditions or Services.

### F.1 Harden route contract

- Required `SourceContext` only entry
- No bottom-nav item for Appointment
- No deep link into Appointment without context (redirect)
- Show context header: “Requesting appointment for: {name}”

**DoD:** Guard proven by automated or manual negative test.

### F.2 API / repository (mock-first)

Endpoints (confirm with backend; mock until ready):

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/appointments/availability?month=` | Available dates |
| GET | `/appointments/availability?date=` | Time slots |
| POST | `/appointments` | Book (must include `sourceContext` + patient + datetime) |

Files: `lib/features/appointment/data/`  
**DoD:** Typed models returned from mock responses.

### F.3 Calendar step (`table_calendar`)

- Disable past dates + unavailable dates
- Context header visible

**DoD:** Selectable dates match availability.

### F.4 Time slot step

- Grid/list of slots for selected date
- Empty state: choose another date
- Selecting slot enables Continue

**DoD:** Date change refreshes slots correctly.

### F.5 Patient details + confirmation

- Form: name, email, phone, notes (confirm required fields vs website/vcita)
- Summary: context + date + time + patient
- POST includes `sourceContext` automatically (user never re-picks condition/service)
- Success screen/snackbar

**DoD:** Logged/mocked payload contains correct source fields.

### F.6 Errors + mid-flow back navigation

- Slot taken / network error → retry without wiping all selections unnecessarily
- Back stack does not duplicate bookings

**DoD:** Forced failure UX verified.

### F.7 Appointment QA

Start from 3+ condition/service screens · no secret entry path · deep link denial  
**DoD:** Checklist signed off.

---

## Phase G — Blog tab

### G.1 `BlogArticle` model + data source

Prefer API if articles change often; otherwise `assets/data/blog.json`.  
Fields: image, title, subtitle, body, author?, date?

**DoD:** Sample parse test passes.

### G.2 `BlogListScreen`

- Cards: image, title, subtitle preview
- Pull-to-refresh; pagination if needed

**DoD:** List scrolls/refreshes.

### G.3 `BlogDetailScreen`

- Hero, title, subtitle, body
- If HTML: add `flutter_html` only when needed

**DoD:** Article matches website formatting reasonably.

### G.4 Optional: Blog → Appointment CTA

Only if product wants it; use `SourceContext(type: blog, ...)`.

### G.5 Blog QA

5+ articles · images · long scroll  
**DoD:** Signed off.

---

## Phase H — Patient tab

### H.1 Dependencies

Add `url_launcher` (and `webview_flutter` only if WebView is chosen).

### H.2 `PatientTabScreen` — **exactly 3 cards**

1. **Patient Portal** → external portal URL  
2. **Book a Service** → per decision #5 (default: jump to Services tab)  
3. **Shop Supplements** → Fullscript URL  

**Never** add Membership.

**DoD:** 3 cards only; grep confirms no membership UI strings/routes.

### H.3 `ExternalLinkHandler` utility

Centralize open-external vs WebView policy.

**DoD:** Portal + Shop open on Android (and iOS when available) without crash.

### H.4 Patient QA

**DoD:** Cards work; Membership absent.

---

## Phase I — FAQ + Chatbot

### I.1 Naming sweep

- Route already `/faq`
- Labels: **FAQ** only
- Grep for “New Patient Questions” → zero hits

**DoD:** Grep clean.

### I.2 FAQ data + accordion UI

- `FaqItem { question, answer }`
- `FaqScreen` with `ExpansionTile` / custom accordion
- Source: scrape `/new-patient-questions/`

**DoD:** All items expand/collapse.

### I.3 Chatbot contract (document before UI)

Write agreed contract in code comments (or short note in this folder):

```
POST /chatbot/message
{ message, conversationId? }
→ { reply, conversationId }
```

Use `CHATBOT_API_KEY` from env (already placeholder in dotenv files).

**DoD:** Contract written before Chatbot UI merge.

### I.4 `ChatbotScreen`

- Bubbles (user/bot), input, send, typing indicator
- Entry: FAB or section on `FaqScreen` (confirm placement)
- Session persistence minimum (memory or `shared_preferences`)

**DoD:** Mock reply path works end-to-end.

### I.5 Chatbot errors

- Disable send on empty input
- Retry on failure

**DoD:** Forced-failure UX verified.

### I.6 FAQ + Chatbot QA

Content accuracy · 10+ sample chatbot prompts  
**DoD:** Signed off.

---

## Phase J — Contact tab (new vs website)

### J.1 Form schema + API contract

Typical fields (confirm): name, email, phone, subject, message  
`POST /contact` → success/failure  

Also show clinic phone/address/hours as static info (useful even if form waits on backend).

**DoD:** Contract documented; backend gap flagged if needed.

### J.2 `ContactScreen` UI + validation

- Email format, required fields, phone format as applicable
- Submit loading state
- Theme tokens only

**DoD:** Invalid submit blocked.

### J.3 Submission handling

- Success → confirm + clear form
- Failure → retry message
- Mock repository acceptable until API exists

**DoD:** Success and failure paths both demonstrated.

### J.4 Contact QA

Valid/invalid · network failure · success  
**DoD:** Signed off.

---

## Phase K — Cross-cutting

### K.1 Images & assets

- Compress local assets
- No uncached `Image.network` for remote content
- Reasonable APK/IPA size

### K.2 Accessibility

- Semantics on buttons, fields, nav
- Contrast via theme tokens
- TalkBack/VoiceOver on About, Conditions, Appointment

### K.3 Analytics / crash (if required)

Suggested events: `appointment_started`, `appointment_completed`, `contact_submitted`, `chatbot_message_sent`  
No Membership events.

### K.4 Deep links

Allow: `/blog/:id`, `/conditions/:id`, `/services/:id`  
**Deny:** bare `/appointment` (must include valid `sourceContext` or redirect)

**DoD:** Positive + negative deep link tests.

---

## Phase L — Final QA & release

### L.1 Full regression script

Walk:

- About (4 subtabs)
- Conditions (8 + appointment CTA)
- Services (all + appointment CTA)
- Appointment from multiple sources
- Blog list + detail
- Patient (3 cards, no membership)
- FAQ + chatbot
- Contact form

Both Android and iOS.

### L.2 Performance

DevTools on list/detail/chat scrolls; fix jank; acceptable cold start.

### L.3 Store prep

Icons, splash, screenshots, listings, privacy policy, permissions justification  
Signed AAB + IPA  
Do **not** mention Membership.

### L.4 Post-launch monitoring

Crash dashboard owner · hotfix/rollback path documented.

---

## Navigation map (target)

```
Bottom nav (5):
  About      → /about
  Conditions → /conditions → /conditions/:conditionId → CTA → /appointment?sourceContext=...
  Services   → /services   → /services/:serviceId     → CTA → /appointment?sourceContext=...
  Blog       → /blog       → /blog/:articleId
  Patient    → /patient    → (external links / services jump)

Secondary (not in bottom nav):
  /faq (+ chatbot entry)
  /contact
  /appointment  ← ONLY with sourceContext
```

**Where FAQ & Contact live in IA:** keep as routes reachable from About footer, Patient area, or app bar actions — confirm UX placement during Phase B/H. They are **not** bottom-nav tabs in the current router skeleton.

---

## Explicit exclusions (do not build)

1. **Membership** tab, card, route, copy, or upsell  
2. **Any Appointment entry** that skips `sourceContext` (including marketing deep links to bare `/appointment`)  
3. Label **“New Patient Questions”** — always **FAQ**

---

## Suggested build order for AI sessions

Paste **Global Conventions** + one bullet per session:

1. `A.1` Brand tokens from website  
2. `A.2` + `A.3` Asset loader + SourceContext  
3. `B.1` → `B.4` About (split if needed: models, then UI)  
4. `C.*` Shared CTA / section widgets  
5. `D.*` Conditions (models → list → detail → CTA → QA)  
6. `E.*` Services (reuse Conditions patterns)  
7. `F.*` Appointment flow  
8. `G.*` Blog  
9. `H.*` Patient (after url_launcher decision)  
10. `I.*` FAQ + Chatbot  
11. `J.*` Contact  
12. `K.*` then `L.*`

---

## Definition of “feature done”

A feature phase is done only when:

- [ ] Screens replace router placeholders  
- [ ] Data loads via repository (JSON or API) with loading/error/empty states  
- [ ] Uses theme tokens only  
- [ ] Appointment CTAs (if any) pass correct `SourceContext`  
- [ ] No Membership references  
- [ ] Basic manual QA vs website content completed  
- [ ] `flutter analyze` clean for touched files  

---

## Appendix — Key paths in this repo

```
lib/
  app.dart
  main.dart / main_dev.dart / main_staging.dart / main_prod.dart
  core/
    config/          # flavors + dotenv
    constants/
    network/         # Dio client + ApiResult + ApiException
    router/          # GoRouter + shell tabs
    theme/           # design tokens
    widgets/         # shared stubs
    utils/
  features/
    about|conditions|services|blog|patient|faq|contact|appointment/
      data|domain|presentation/
env/
  .env.dev .env.staging .env.prod
assets/              # create in Phase A.2
  data/
```

**Run:**

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter analyze
flutter test
flutter build apk --flavor dev -t lib/main_dev.dart --debug
```

---

*This plan supersedes the original phase numbering for day-to-day execution while preserving every product constraint from that document. Update the progress table as steps complete.*
