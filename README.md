# Hydration Tracker

A small but complete Flutter + Firebase app: track daily water intake, see weekly
insights, and ask an in-app AI assistant about your hydration. Built to
demonstrate Firebase Auth, Firestore, Cloud Functions, Firebase AI Logic, and a
clean, layered architecture.

| | |
|---|---|
| **Stack** | Flutter · `flutter_bloc` (Cubit) · `freezed` · Firebase |
| **Screens** | Auth · Home (per-day) · Insights (this week) · AI assistant |
| **Backend** | Firestore + 2 Cloud Functions (TypeScript) + AI Logic |

---

## What it does

- **Auth** — email/password and Google sign-in, validation, friendly errors,
  persisted session, sign-out.
- **Home (per-day)** — a day selector (defaults to today; changing the day
  reloads everything), a circular progress ring, quick-add (+250 / +500 /
  custom), and the day's logs with swipe-to-delete + undo. The ring reads the
  **server-computed** daily summary — the client never sums logs itself.
- **Insights** — calls the `getWeeklyInsights` callable and shows weekly total,
  daily average, adherence (days goal met), current streak, week-over-week trend,
  and a 7-bar visual (plain Containers, no chart library).
- **Assistant** — a chatbot on Home that calls **Gemini via `firebase_ai`**
  directly from the app, grounded in the selected day's totals, scoped to
  hydration/wellness and deferring medical questions.

---

## Architecture

Clean Architecture with a strict one-directional data flow, applied per feature:

```
UI (Widget) → PageCubit → Repository (abstract) → DataSource → Firebase
Firebase → DTO (@JsonSerializable) → mapper → Entity (@freezed) → Cubit state → UI
```

**Non-negotiables that are honored throughout:**

- Cubits depend only on **abstract repository interfaces** — never on a data
  source or Firebase directly.
- **All** Firebase / Firestore / AI calls live in the **DataSource layer only**.
  No `FirebaseFirestore.instance` (or similar) in cubits or widgets.
- DTOs use `@JsonSerializable`; domain entities use `@freezed`; mapping between
  them is **explicit** (`toDomain()`).
- **One page-cubit per screen** for UI state (loading / data / error).
- Dependencies are **constructor-injected** and registered in `injector.dart`.

### Project structure

```
lib/
├── core/
│   ├── di/injector.dart            # get_it composition root
│   ├── theme/app_colors.dart
│   ├── data/timestamp_converter.dart
│   ├── date_key.dart               # local YYYY-MM-DD helper
│   └── app_constants.dart
└── feature/
    ├── auth/
    │   ├── data/{datasources, models, repositories}
    │   ├── domain/{entities, repositories}
    │   └── presentation/{cubit, pages, widgets}
    ├── hydration/
    │   ├── data/{datasources, models, repositories}
    │   ├── domain/{entities, repositories}
    │   └── presentation/{cubit, pages, widgets}
    └── assistant/                  # the Firebase AI Logic chatbot
        ├── data/                   # chat_remote_data_source (firebase_ai), dto, repo impl
        ├── domain/                 # chat_message (@freezed), chat_repository
        └── presentation/           # chat_cubit, chat_sheet

functions/                          # the two Cloud Functions (TypeScript) + README
firestore.rules                     # per-user access rules
```

### Firestore data model

```
users/{uid}
 ├── water_logs/{logId}        amountMl, createdAt (server ts), dateKey
 └── daily_summaries/{dateKey} totalMl, goalMl, logCount, goalMet, updatedAt
```

`water_logs` is the append-only source of truth. `daily_summaries` is a
denormalized read-model written **only** by the trigger, so Home fetches one
document instead of reading and summing every log. The doc id **is** the
`YYYY-MM-DD` day key, decided on the client to avoid server timezone math.

### Cloud Functions

See [`functions/README.md`](functions/README.md). In short:

- **`onWaterLogWritten`** (Firestore trigger) — recomputes the daily summary
  from raw logs on create/update/delete. Idempotent; never trusts a client
  total; undo (delete) lowers the total.
- **`getWeeklyInsights`** (callable) — auth-guarded; reads 14 days server-side
  and returns one compact payload (total, average, adherence, streak, trend).

---

## Running it

> The app needs your **own** Firebase project. Secrets are **not** committed
> (`google-services.json`, `GoogleService-Info.plist`, `lib/firebase_options.dart`
> are gitignored) — generate them with the steps below.

### 1. Firebase project setup

1. Create a Firebase project on the free **Spark** plan
   (deploying Functions requires upgrading to **Blaze** — the free allowance
   covers this exercise at no cost).
2. In the console: enable **Authentication → Email/Password and Google**, create
   a **Firestore** database, and turn on **Firebase AI Logic** using the
   **Gemini Developer API** backend (free tier).
3. Configure FlutterFire (regenerates `lib/firebase_options.dart` and the
   platform config files):
   ```bash
   flutterfire configure
   ```

### 2. App

```bash
flutter pub get
dart run build_runner build           # generates *.freezed.dart / *.g.dart

# Android needs the OAuth *web* client id for Google id tokens.
# Passed at build time so no secret is committed:
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<your-web-client-id>
```

### 3. Backend (Cloud Functions + rules)

```bash
cd functions && npm install && cd ..
firebase deploy --only functions       # deploys both functions
firebase deploy --only firestore:rules # deploys security rules
```

---

## Security

- **Firestore rules** (`firestore.rules`) lock each user to their own
  `users/{uid}` subtree. Logs are create/delete-only; daily summaries are
  read-only to clients (written solely by the Cloud Function via the Admin SDK),
  enforcing the server-owned trust boundary. Everything else is denied.
- **App Check (not wired — known risk).** Calling Gemini straight from the
  client exposes the AI Logic endpoint to abuse. Firebase recommends **Firebase
  App Check** to attest requests. It is a documented next step here, not a
  requirement, but the risk is real and called out deliberately.
- No secrets are committed; Firebase config is generated locally.

---

## Decisions & trade-offs

- **Server-owned summaries.** The client reads `daily_summaries` and never sums
  logs, so the ring/totals come from one document kept correct by the trigger.
  The trigger recomputes from scratch (idempotent) rather than incrementing, so
  it is safe to re-run and handles undo correctly.
- **Client-side log sorting.** `water_logs` are queried by `dateKey` equality
  and sorted newest-first in Dart, avoiding a composite index (a day holds few
  logs). Listed as an index trade-off rather than added complexity.
- **Day decided on the client.** The local `YYYY-MM-DD` is passed to both
  Firestore (as the summary id) and the callable, so there's no timezone math on
  the server.
- **Assistant grounding lives in the repository**, not the widget: the chat
  repository pulls the day's summary from the hydration repository and builds the
  prompt context, keeping the SDK call out of the UI.
- **Generated code is gitignored** (`*.freezed.dart`, `*.g.dart`) with a single
  documented `build_runner` step, keeping the repo clean.

## With more time

- Wire up **Firebase App Check** to protect the AI Logic endpoint.
- **Stream** the assistant's reply token-by-token.
- **Unit-test** repositories/cubits with mocked data sources (and the date-key /
  trend / streak logic in the functions).
- Offline support via Firestore persistence; account-linking when the same email
  is used for both providers.

---

## Scope

Deliberately three screens plus the assistant. No charts library, theming
system, settings page, or notifications — those are out of scope by design.
