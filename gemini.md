# Gemini Project Memory: Student Quiz Platform

This file stores persistent project context so Gemini never loses important decisions between conversations.

---

## 🚨 Mandatory: The "Changelog First" Rule

**No task is considered "Done" until it is recorded in the `README.md` changelog.**

### Why?
This project relies on "Project Memory" (this file + `README.md`) to maintain context across sessions. If you change a feature, fix a bug, or update a dependency without recording it, **Gemini (and other LLMs) will lose track of the app's current state**, leading to context drift, hallucinations, and broken code in future turns.

### The Developer/LLM Workflow:
1.  **Implement**: Make the code changes.
2.  **Verify**: Run `& "C:\flutter2\bin\flutter.bat" analyze` and test the feature.
3.  **Version**: If it's a significant feature or fix, increment the version in `pubspec.yaml`.
4.  **LOG**: Immediately update the `## 📋 Changelog` section in `README.md` using the standard format.

---

## 🗂️ Project Overview

**Name**: Student Quiz Platform (`student_quiz_app`)  
**Type**: Flutter mobile app (Android primary, Web secondary, Windows supported)  
**Purpose**: Secure, bilingual (EN/AR) exam platform for academic institutions with anti-cheating tools and real-time admin monitoring.  
**Location**: `c:\Users\memja\OneDrive - uokerbala.edu.iq\Desktop\the ai\outo platfrom`

---

## 🛠️ Environment

| Tool | Location |
|---|---|
| Flutter SDK | `C:\flutter2` |
| Android SDK | `C:\Users\memja\AppData\Local\Android\sdk` |
| Dart SDK | `^3.7.0` (Configured in pubspec.yaml) |
| Gradle | `C:\flutter2\gradle-8.7` (Binary) |
| `local.properties` | Configured with `C:\flutter2` |

> **Note**: `flutter` is NOT in the system PATH. Always use the full path: `& "C:\flutter2\bin\flutter.bat"`
> **Note**: Gradle 8.7 and Dart SDK are also available in `C:\flutter2\`.

> [!WARNING]
> **No Localhost Backend**: There is no local XAMPP/Laragon environment running for testing the backend. The project relies entirely on the live production API at `http://s.nabuo.org`. **Any edits or hotfixes made to the local `server/` directory will NOT be reflected in the Flutter App during testing until they are manually uploaded via FTP to `s.nabuo.org`.**

---

## 📐 Architecture Conventions

- **Routing**: `go_router` (declarative). Use `context.push()` for overlay navigation, `context.go()` for replacing the stack.
- **State Management**: `provider` package. `QuizService` and `LanguageProvider` are global providers.
- **Localization**: All user-facing strings MUST use `.arb` keys (`lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`). Never use inline `l10n.localeName == 'ar' ? '...' : '...'` ternaries.
- **Platform Guards**: Use `isMobilePlatform` from `platform_utils.dart` before calling any mobile-only API (recording, window manager, biometrics).
- **Token Security**: Admin JWT stored via `flutter_secure_storage` (NOT `SharedPreferences`).
- **Offline**: `QuizService.isOffline` flag is set when backend fetch fails. UI should show a banner.

---

## 🔑 Key Files

| File | Role |
|---|---|
| `lib/main.dart` | App entry, GoRouter config, WelcomeScreen |
| `lib/services/quiz_service.dart` | God-class for all API, state, offline sync (candidate for refactoring) |
| `lib/services/app_config.dart` | Set `productionHost` here before building for production |
| `lib/models/quiz_model.dart` | All data models |
| `lib/screens/quiz_screen.dart` | Core exam UI (~850 lines, complex) |
| `android/local.properties` | Flutter + Android SDK paths |
| `README.md` | **The Primary Source of Truth** (Project docs + Changelog) |

---

## 📋 Changelog Convention

**Every significant change to the app must be recorded in `README.md`** under the `## 📋 Changelog` section. Use the format:

```
### [YYYY-MM-DD] — Description (vX.Y.Z)
#### Category (🔴 Critical / 🔒 Security / 🧰 Code Quality / 🎨 UX / ♿ Accessibility / 📦 Dependencies)
- Description of change

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.0 -> 1.3.1) for every significant feature or fix. Update the version in `db_connect.php` (setting_value) and `walkthrough.md`.
```

---

## ✅ Recent Improvements (as of 2026-03-18)

- **Instructional Upgrade**: Added "Changelog First" mandatory rule to `gemini.md`.
- **Roadmap Planning**: Defined AI Gaze Tracking, Biometric ID, and Kiosk Mode as future security goals.
- **Dev Playbook**: Added "The 5-Step Feature Workflow" and "Localization Rules" to project memory.
- **UI Architecture**: Added plan to migrate to a modern Theme System and Clean Architecture.
- **Leaderboard & Instructions**: Built the Global Leaderboard and refined the Exam Instructions landing page.
- **Localization Cleanup**: Retroactively localized all trailing raw English text instances.

---

## 🚧 Known Remaining Improvements (future work)

- Split `QuizService` into `AuthService`, `QuestionService`, `ExamService`, `ResultService`
- Extract `WelcomeScreen` from `main.dart` into its own file
- Replace 15-second heartbeat with WebSockets for real-time admin monitoring
- Add SSL certificate pinning
- Add unit and widget tests
- Add teacher-facing analytics dashboard (time-per-question, distractor analysis)

---

## 🚀 Proposed New Features

### 🛡️ Enhanced Security & Proctoring
- **AI Gaze Tracking**: Use Google ML Kit to detect if a student looks away from the screen for too long.
- **Biometric Identity**: Require Fingerprint/FaceID before starting a high-stakes exam.
- **Device Locking**: Implement "Kiosk Mode" (Screen Pinning) to prevent app-switching on Android.

### 📚 Rich Content & Interaction
- **Multimedia Questions**: Support for image-based options, video prompts, and audio snippets.
- **Mathematical Rendering**: Integrate `flutter_math_fork` for LaTeX support in STEM exams.
- **Interactive Map Questions**: For geography or civil engineering quizzes.

### 📶 Robust Offline Support
- **Full Offline Exams**: Download exam data (including media) in advance and upload results automatically once back online.
- **Delta Sync**: Sync only the answers that changed to save bandwidth.

---

## 🛠️ Architectural & Code Improvements

- **Clean Architecture**: Migrate from the current service-based approach to a Layered Architecture (Data -> Domain -> Presentation).
- **Theme System**: Implement a `ThemeData` extension for custom university branding and consistent Dark/Light mode support.
- **Centralized Error Handling**: Implement a global `ErrorHandler` that logs to a service like Sentry and shows user-friendly Snackbars.
- **CI/CD Pipeline**: Setup GitHub Actions to run `flutter analyze` and `flutter test` on every Pull Request.

---

## 📖 Mobile Development Instructions (The Playbook)

### 1. The 5-Step Feature Workflow
1.  **Define Model**: Create/Update the Dart class in `lib/models/`.
2.  **Update Service**: Add the necessary API call in the specialized service (e.g., `ExamService`).
3.  **Add Localization**: Add English and Arabic keys to `.arb` files. Run `& "C:\flutter2\bin\flutter.bat" gen-l10n`.
4.  **Build UI**: Create a responsive widget. Use `LayoutBuilder` if behavior differs on tablets.
5.  **Platform Guard**: If using hardware (Camera/GPS), check `isMobilePlatform` and request permissions.

### 2. Localization Rules
- **Never** hardcode strings. Use `AppLocalizations.of(context)!.keyName`.
- For pluralization (e.g., "1 Minute" vs "5 Minutes"), use ARB plural syntax.
- Always test the UI in **Right-to-Left (RTL)** mode by switching the app language to Arabic.

### 3. State Management Best Practices
- Keep `ChangeNotifier` classes small. If a service exceeds 300 lines, split it.
- Use `context.select<T, R>()` to rebuild only when specific properties change, improving performance in the `QuizScreen`.

### 4. UI/UX Consistency
- Use `Skeletonizer` for loading states instead of simple spinners.
- All buttons must have a minimum touch target of 48x48 dp.
- Use `SafeArea` to avoid notches and system navigation bars.

### 5. Running Commands (Reminder)
Since Flutter is not in the PATH, use these aliases:
- **Run App**: `& "C:\flutter2\bin\flutter.bat" run`
- **Gen L10n**: `& "C:\flutter2\bin\flutter.bat" gen-l10n`
- **Analyze**: `& "C:\flutter2\bin\flutter.bat" analyze`
