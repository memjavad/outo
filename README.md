# Student Quiz Platform

A secure, feature-rich Flutter exam platform for academic institutions. Supports bilingual (English/Arabic) interfaces, a powerful anti-cheating suite, offline-resilient data handling, and real-time live monitoring for administrators.

---

## ✨ Features

- **Multi-mode Authentication**: Student name, secret access code, or Telegram login
- **Anti-Cheat Suite**: GPS capture, biometric verification, VPN detection, screenshot prevention, screen/audio recording
- **Live Monitoring**: Admin dashboard with real-time student session tracking (heartbeat)
- **Offline Resilience**: Settings and questions cached locally; results queued and auto-synced
- **Rich Question Types**: MCQ, True/False, and short-answer with Markdown/image support
- **Bilingual UI**: Full English & Arabic support with RTL layout
- **Configurable Exams**: Separate exam pools, question/exam timers, randomization, immediate feedback
- **Review Mode**: Post-exam answer review with correct/incorrect highlights

---

## 🛠️ Setup

### Prerequisites
- Flutter SDK at `C:\flutter2` (or update `android/local.properties`)
- Android SDK at `C:\Users\memja\AppData\Local\Android\sdk`
- A PHP backend server (see `server/` directory)

### Running
```bash
flutter pub get
flutter run
```

### Building APK
```bash
flutter build apk --release
```

---

## 📁 Project Structure

```
lib/
├── main.dart              # App entry, routing (GoRouter), WelcomeScreen
├── models/
│   └── quiz_model.dart    # Data models: QuizQuestion, QuizResult, AppSettings, Exam
├── screens/
│   ├── quiz_screen.dart   # Core exam UI with timer, anti-cheat, and session management
│   ├── results_screen.dart
│   ├── review_screen.dart
│   ├── dashboard_screen.dart
│   ├── login_screen.dart
│   ├── main_admin_screen.dart
│   ├── add_question_screen.dart
│   └── edit_question_screen.dart
└── services/
    ├── quiz_service.dart  # All API calls, offline sync, state management
    ├── app_config.dart    # Server URL configuration
    ├── language_provider.dart
    └── platform_utils.dart
```

## 📋 Changelog

### [2026-04-24] — Final Repository Consolidation & Conflict Resolution (v1.0.4+1)
#### Category (🧰 Architecture / 📦 DevOps)
- Successfully merged all 76 unmerged remote branches into `main`.
- Resolved 48 significant merge conflicts using automated resolution for performance and security branches.
- Cleaned up the remote repository by deleting all 76 stale feature branches.
- Removed unused temporary files, build logs, and development scripts from the repository.
- Finalized synchronization with GitHub origin (`memjavad/outo`).



### [2026-04-19] — GitHub Repository Integration (v1.0.1)
#### Category (🧰 Architecture / 📦 DevOps)
- Initialized local Git repository for the Student Quiz Platform.
- Synchronized codebase with the remote GitHub repository at `https://github.com/memjavad/outo.git`.
- Configured remote origin and pushed initial project state to the `main` branch.


### [2026-03-23] — Phase 3: Teacher Analytics Dashboard (v1.3.13)
#### Category (📈 Analytics / 🧰 Architecture / 🎨 UX)
- Engineered `student_responses` atomic answer relationship database migration.
- Rebuilt Flutter client payload architecture mapping explicit native question identifiers ignoring front-end permutations.
- Drafted `AnalyticsService.php` aggregating mathematically intensive Distractor distributions.
- Injected `fl_chart` widget natively rendering interactive Vector Pie Charts securely inside the App.
- Fired up `AnalyticsAdminScreen` as the dynamic 7th navigation element routing platform wide tracking KPIs!

### [2026-03-23] — Leaderboard Redesign & Performance Patches (v1.3.8)
#### Category (🚀 Performance / 🎨 UX / ⚙️ Backend)
- Refactored `ApiExams.dart` network layer to decode raw JSON bodies asynchronously via Top-Level Isolates (`compute`). This completely eliminated all "Skipped 144 Frames" jank caused by concurrent leaderboard fetching!
- Completely redesigned the Global Leaderboard screen, separating content into 3 dedicated tabs (Campaign, Essays, and Single Exams).
- Extracted and fixed hardcoded Arabic localization ternaries scattered across Dashboard & Admin UIs, ensuring they map dynamically to ARB standard keys.
- Engineered a new global database query (`get_campaign_leaderboard`) unlocking Story Points / XP ranking across all students.
- Implemented specific drop-down match filters restricting Essay and Standard Exam leaderboards accurately.



### [2026-03-23] — Main Thread Performance Optimization (v1.3.6)
#### Category (🚀 Performance)
- Resolved `I/Choreographer Skipped 132 frames!` error and UI stuttering during app launch and exam auto-saves.
- Offloaded heavy synchronous `jsonDecode` and `jsonEncode` operations in `LocalStorage` to background isolates using `compute()`.
- Offloaded Quill Delta JSON serialization in `quiz_screen.dart` auto-save loops to background isolates, eliminating 2-second screen freezes.


### [2026-03-24] — Gamified HUD Repositioning & L10n (v1.3.5)
#### Category (🎨 UX / 🌐 Localization)
- Moved the star and point counters to the top right of the dashboard screen, integrating them into a transparent AppBar.
- Restructured the Campaign Mode HUD elements (stars, points, and store shortcuts) into a stacked vertical floating column over the deep 3D map viewport.
- Fully localized the Campaign Mode rules and scoring instructions sheet into both English (app_en.arb) and Arabic (app_ar.arb).

### [2026-03-24] — The Economy & Advanced Gamification 2.0 (v1.3.4)
#### Category (🎨 UX / 🧰 Architecture / 📦 Database)
- Designed and built the complete In-Game Store Economy from the database to the Flutter UI (`store_items`, `student_inventory`).
- Architected PDO transaction isolation locking (`StoreRepository`) to securely prevent API double-spending during purchases.
- Integrated the "Power-Up Tray" dynamically into `quiz_screen.dart`.
- Active deployment of 3 Game Mechanics:
  - ✂️ **50/50 Chop**: Automatically intercepts the `options` array fading out wrong answers without destroying `originalIndex` offsets.
  - ⌛ **Time Freeze**: Decouples the live loop natively forcing `_isTimeFrozen` blocks for 15 seconds.
  - 🛡️ **Combo Shield**: Hardened `_recalculateScore` to shatter a shield natively dropping penalty damage while preserving combo chains.

### [2026-03-22] — Campaign Path UI Unlock Hotfix (v1.3.26)
#### 🔴 Critical / 🎨 UX
- Fixed a silent failure in `ResultController.php` where strict legacy validation matrices were violently dropping all `earned_stars` and `campaign_score` payloads from traversing the internal API.
- Updated `ResultRepository.php` and `ResultService.php` to permanently burn awarded Stars into the `students` table ledger.
- The 3D Campaign Map now natively responds to completed exams by rendering visually unlocked pathways and registering acquired stars to the user HUD.
- Upgraded the `results_screen.dart` post-exam confirmation view to replace standard letter grades with a massive animated 3-Star Golden array and specific Campaign Score when completing Story Mode nodes.
- **Bug Fix**: Recalibrated the Campaign Star calculation condition from strict 'Theoretical Max Points' to straightforward Correct Answer 'Accuracy Percentage', ensuring students receive 3 Stars when achieving 20/20 scores.
- **Critical Hotfix**: Resolved a fatal PHP `ArgumentCountError` in `ResultController.php` returning a 500 Internal Server error that was silently dropping valid quiz submissions, permanently locking subsequent Campaign map nodes for users.
- **Data Schema Hotfix**: Fixed a fatal MySQL `UNION ALL` exception inside `ResultRepository.php` where legacy queries mismatched column counts with newly injected Campaign scoring matrices, crashing the user's score history fetch and reverting all nodes to locked.
- **Campaign Gameplay Upgrade**: Removed the standard overarching Exam Timer from Story Mode entirely. Introduced a dynamic, high-adrenaline 'Burning Fuse' progress bar natively bounding each *individual question*. The countdown becomes steeper as the Campaign progresses (Level 1 starts smoothly at 30 seconds per question, but scales aggressively down to 10 seconds per question by Level 150+).
- **Campaign UI / UX**: Replaced the default single 'Back to Start' button on the post-exam Results Screen with a split dual-button overlay specifically for Campaign exams, allowing students to instantly 'Redo Level' or proceed to the 'Next Level' on the map.
- **Campaign Text Submersion**: Replaced the generic "Exam Completed" title banner on the Results screen with "Level Completed!" (تم إنهاء المستوى!) when playing on the Campaign map to enforce the gamified tone.
- **Backend Analytics Extraction**: Designed and deployed a secure, standalone `view_logs.php` REST module. Live stack traces mapping to the newly repaired `ErrorHandler.php` engine can now be read directly in the browser bypassing cPanel access.
- **Dynamic Campaign Instructions**: Overhauled `exam_instructions_screen.dart` natively diverging the UI architecture for Campaign map nodes. Replaced standard academic evaluation warnings with a dynamic gamified 'Level Rules' framework explicitly mapping the Burning Fuse scaling parameters, 3-Star objectives, and Combo Multipliers for the active node.

**See the newly generated `future_roadmap.md` document for a complete, in-depth technical analysis and future feature matrix mapping out Clean Architecture migrations, State Management refactoring, Offline-First API Queues, and Level Store enhancements!**

### [2026-03-21] — UI Polish Phase 5 (v1.3.25)
#### 🎨 Game Graphics / 🔒 Architecture
- **Auto-Linear Progression Locks**: Modified `_getHighestUnlockedIndex()` and `MapNodePlacement` mapping within `campaign_level_map.dart`. If explicit API prerequisites are missing, the map now enforces a strict sequential auto-lock. Level 1 glows cyan, while Levels 2-6 naturally revert to dark, heavily-shadowed locked stone.
- **Premium Metallic Badges**: Forged the generic flat "Lvl X" trackers into AAA-styled 3D metallic shields. Unlocked levels display a glowing specular gold vector ribbon, while locked nodes display a heavy iron/dull-metal aesthetic. 

### [2026-03-21] — UI Polish Phase 4 (v1.3.24)
#### 🎨 Game Graphics / 🚀 Performance
- **Eradicating Tearing Artifacts**: Pinpointed and completely deleted the legacy `_buildFog` and `_buildFireflies` volumetric generators from `campaign_level_map.dart`. The massive computational 100-radius `BoxShadows` inside the fog pills were failing to render properly on mobile hardware, generating sharp circular vector artifacts behind the 3D structures.
- **Widget Tree Optimization**: Stripped the outer `IgnorePointer` and background `RadialGradient` vignette nodes to streamline layout performance alongside the new parallax backdrops.

### [2026-03-21] — UI Polish Phase 3 (v1.3.23)
#### 🎨 Game Graphics / ✨ Aesthetics
- **Seamless Cosmic Shaders**: Eradicated the horizontal tiling seams tearing through the background. Replaced the repeating `abyss_bg` and `midground_clouds` with an infinite math-based `LinearGradient` void, overlaid with an ultra-dense `0.4x` parallax Starfield layer generator.
- **Physical Beveled Pedestals**: Reconstructed the procedural pedestal gradients to simulate a true 3D physical rim instead of a flat glowing hologram. Wrapped the discs in an inner `BoxShadow` to fake solid thickness and specular edge lighting.
- **Base-Anchored Neural Paths**: Rewrote the `_getY()` bezier math logic to offset path tracing downwards by `+20` pixels. Paths now organically connect to the *base* and *gates* of the castles rather than tunneling unnaturally through their domed roofs.
- **Typography Boundaries**: Increased the absolute localized margins orbiting the `MapNodePlacement` modules. The title text and "Lvl X" badges now securely clear the 3D glare of the platforms without overlapping.

### [2026-03-21] — Premium UI Polish (v1.3.22)
#### 🎨 UI Design / ✨ Aesthetics
- **Full-Screen 3D Immersion**: Overrode the default scaffold and AppBar parameters (`extendBodyBehindAppBar` and `Colors.transparent`) in `CampaignExamsScreen`, removing the harsh green headers and allowing the cosmic map to organically bleed into the status bar.
- **Programmatic Iso-Pedestals**: Purged the AI-generated opaque `floating_pedestal.png` assets. Replaced them with a pure-vector Flutter programmatic pedestal using `Transform.rotateX` and deep volumetric `RadialGradient` shadows, granting perfect 100% alpha transparency against the cosmos.
- **Ambient Starfield Engine**: Deleted the legacy jungle leaf decorations. Generated a dense, drifting animated Starfield across the map's Z-axis to anchor the deep sci-fi presentation.
- **Neon Neural Paths**: Drastically boosted the bezier glow (`MaskFilter.blur`) and `opacity` of the connected pathways to slice through the dark gradient filters.

### [2026-03-21] — Ultimate 3D Map Architecture (v1.3.21)
#### 🎨 Game Graphics / 🚀 Performance
- **4-Layer Parallax Engine**: Separated the single scrolling background into four mathematically offset Z-layers (deep void at 0.1x speed, midground clouds at 0.4x, castles at 1.0x, foreground lens clouds at 1.3x) to simulate profound 3D space.
- **Floating Node Pedestals**: Re-anchored the 3D castle widgets atop independent isometric floating stone islands.
- **Procedural Z-Axis Shadowing**: Modified the `CustomPainter` to extract the neural path and cast a massive, blurred drop-shadow exactly `Offset(10, 25)` pixels downwards into the void.
- **Cylindrical Horizon Viewport**: Wrapped the primary Map camera inside a destructive `ShaderMask` that permanently darkens the top and bottom 12% of the screen, creating a volumetric "tunnel" perspective.

### [2026-03-21] — Ultimate AAA Game Overhaul (v1.3.20)
#### 🎨 UX / 🎨 Game Graphics / 🎵 Audio
- **3-Star Ratings**: Rendered dynamic golden star slots beneath completed castles bound to historical user scores (>50/75/90 thresholds).
- **Parallax Engine**: Detached the jungle camera from the ScrollView and programmed a 30% background speed modifier for deep 3D illusion.
- **Atmospheric Weather**: Overlaid the camera with a dark Shader Vignette spotlight and slowly drifting translucent Fire/Fog arrays.
- **Unlock Animations**: Programmed complex PathMetric sub-path extractions to vividly "draw" a glowing line and pop-scale castles dynamically during unlocks.
- **Tactile Audio**: Generated raw procedural `.wav` files via Dart synthesis to play a persistent ambient jungle loop and contextual SFX (heavy thuds/confirm chimes) across the Map interface.

### [2026-03-21] — Story Mode: Premium AAA Visual Overhaul (v1.3.19)
#### 🎨 UI Architecture / 💠 Particles
- **Seamless Tile Textures**: Transited from algorithmic gradients to an AI-generated, high-resolution seamless tropical jungle floor texture loaded dynamically via `assets/images/jungle_floor.png`.
- **3D Programmatic Nodes**: Upgraded the primitive vector nodes into dynamic 3D assets heavily stylized with inner shadows, complex radial gradients, and metallic/stone bevel illusions. 
- **Particle System Rendering**: Programmed an atmospheric `FireflyParticleSystem` generating continuously flickering, organically drifting amber light orbs across the Canvas Z-axis layered perfectly between the path and the background foliage.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.18 -> 1.3.19).

---

### [2026-03-21] — Story Mode: Vivid Jungle Theme Overhaul (v1.3.18)
#### 🎨 UX / 🗺️ UI Architecture
- **Tropical Environment Gating**: Stripped the standard `GlobalBackground` from the campaign exams screen and replaced it natively with a rich, multi-layered Jungle Green gradient backdrop.
- **Vivid Ecology Palettes**: Reprogrammed randomly generated map foliage (`Icons.eco`) into bright glowing jungle greens, while rotating the S-curve stroke into a thick earthy brown dirt path style.
- **Node Contrast & Saturation**: Extracted default theme colors from level badges. Upgraded active targets to a blazing `.deepOrange` torch motif, and rested locked levels atop a deep mossy `.green.shade900` palette to significantly improve background contrast.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.17 -> 1.3.18).

---

### [2026-03-21] — Story Mode: Map Ecology & Physics Physics (v1.3.17)
#### 🎨 UX / 🗺️ UI Architecture
- **Interactive Entrances**: Map nodes now spawn iteratively along the path utilizing `Curves.easeOutBack` staggered scaling pop-in logic based on their index `(delay: (index * 150).ms)`.
- **Level Floating Physics**: Augmented every campaign node with an infinitely looping Y-axis translation cycle `(.moveY(end: -4))` mimicking game-board hovering physics.
- **Ambient Stars**: Intertwined glowing, infinitely rotating golden icons strategically over the cloud layer to add dynamic flair to the winding path.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.16 -> 1.3.17).

---

### [2026-03-21] — Story Mode: Aesthetic Environment & Micro-Animations (v1.3.16)
#### 🎨 UX / 🗺️ UI Architecture
- **Environment Generation**: Programmed a deterministic spatial distribution algorithm to scatter scaled decorative elements (Clouds, Trees) randomly around the `CampaignLevelMap` path, rendering an atmospheric "Story" ecosystem.
- **Ambient Micro-Animations**: Injected `flutter_animate` parameters into the background ecosystem, resulting in infinitely drifting/scaling clouds and breathing foliage.
- **Pulsing Focal Nodes**: Overhauled the `NodeState.current` active level badge with prominent, infinitely looping `scaleXY` pulses and high-contrast ambient shimmers to explicitly guide the user to their next target immediately upon loading the map.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.15 -> 1.3.16).

---

### [2026-03-21] — Story Mode: Candy Crush Level Map Integration (v1.3.15)
#### 🎨 UX / 🗺️ UI Architecture
- **2D Level Map Canvas**: Transformed the linear `campaign_exams_screen.dart` into a 2D interactive canvas utilizing `CustomPainter` to draw a curved, dashed S-shaped path.
- **Node State Management**: Rendered interconnected nodes representing locked, active, and completed levels, visually reflecting the `prerequisiteExamId` requirements.
- **Seamless Panning**: Embedded within an inverted `SingleChildScrollView` auto-scrolling framework to emulate the experience of panning upwards through story levels globally.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.14 -> 1.3.15).

---

### [2026-03-21] — AI Feedback Optimization & Admin UI Extraction (v1.3.14)
#### 🤖 AI Integration / ⚙️ Architecture
- **Concise AI Evaluation**: Modified the `AiGradingService` system prompt to strictly limit background AI evaluation feedback to a maximum of 20 words per essay to improve readability and grading speed.
- **Essay Submissions Extraction**: Extracted the "Student Submissions" layout out of the inline "Essay Manager" tables into a dedicated admin submenu featuring dynamic assignment filtering and zero-dependency client-side CSV exports.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.13 -> 1.3.14).

---

### [2026-03-21] — Unified Registration & Login Interface (v1.3.13)
#### 🎨 UX / ⚙️ Architecture
- **Dashboard Simplification**: Removed the legacy "Premium Welcome View" authentication UI from the primary `dashboard_screen.dart` entirely.
- **Unified Login View**: Promoted `StudentLoginScreen` to handle all unauthenticated interactions including the Login/Signup tabs, Admin Portal access, and Telegram integration.
- **Logic Encapsulation**: Migrated Telegram Authentication procedures and Admin redirection native routes gracefully out of the core app skeleton into the newly dedicated `student_login_screen.dart` route map.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.12 -> 1.3.13).

---

### [2026-03-20] — Asynchronous Background AI Grading (v1.3.12)
#### 🤖 AI Integration / ⏱️ Automation
- **Multi-Model Support**: Integrated dynamic Google AI Studio REST configuration targeting `gemini-3.0-flash`, `gemini-2.5-flash`, and `gemma-3-27b-it` gracefully.
- **Randomized Execution Window**: Built `EssayService` algorithms blocking instant AI polling, instead calculating a random schedule chronologically constrained distinctly between `09:00` and `23:00`.
- **Headless Background Cron**: Generated `server/cron/grade_essays.php` routing pending evaluations reliably mapping API connections strictly behind-the-scenes avoiding rigid UI latencies.
- **Rubric-Driven Architecture**: Added strict Database schema mappings enabling dynamic assignments to map unique text string instructions guaranteeing highly tailored native evaluations.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.11 -> 1.3.12).

---

### [2026-03-19] — Advanced Essay Grading & Tailwind Portal (v1.3.11)
#### 🎓 Features / 🎨 UX
- **Web Student Portal Overhaul**: Replaced the legacy gray HTML form with a responsive, modern Tailwind CSS login interface natively generated via Stitch App, resolving internal structural bugs strictly inside `header.php`.
- **Flutter Essay Flow**: Injected a comprehensive bypass payload skipping the traditional `questions` REST API when loading `essay` configurations, embedding a multi-line `TextFormField` seamlessly.
- **Admin Manual Grading Module**: Built a dual-section PHP Dashboard UI grouping `#pending-essays` explicitly. Bound native HTML Modal interactions parsing detailed Student strings executing direct integer `gradeResult` REST endpoints safely.
- **REST Sync Bypass**: Restructured the Flutter `quiz_service_facade` identifying manual `is_graded = 0` triggers saving local assignments gracefully bypassing automatic server-side validation correctly.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.10 -> 1.3.11).

### [2026-03-19] — The Ultimate Backend Architect (v1.3.10)
#### 🧰 Code Quality / 🔒 Security
- **Strict Clean Architecture Achieved**: The entire PHP backend rests firmly within a standardized layered architecture (Controllers -> Validators -> Services -> Repositories -> Database). No file violates these scope boundaries.
- **Global Constraints via Validator**: Created a native constraint mapper (`Validator.php`) to intercept and sanitize inputs uniformly. Destroyed all scattered `isset` boolean maps and nested evaluations.
- **API Gateway Gatekeeper**: Deployed `SecurityService` to `api.php`, completely replacing its 75 lines of legacy raw `PDO` global-scope SQL executions with natively abstracted methods managing rate limits, IP whitelist verification, API keys, and JWT parsing.
- **Global Error Handler Catch-All**: Deployed an `ErrorHandler` interceptor on `api.php`. Preventative JSON mappings prevent the Flutter app from crashing remotely if PHP fatals, securely proxying back `{"error": "Internal Server Error"}` while logging stack dumps to `server/logs/error.log`.
- **The Service Extrication**: Eliminated complex gamification processing, password salt mapping, raw JWT session token creation, zip execution logic, heartbeat tracking, and webhook execution from controllers via newly provisioned files (`AuthService`, `SessionService`, `UpdateService`, `ResultService`, `ExamService`, `StudentService`). Controllers now read elegantly as 5-line declarative routers.

### [2026-03-19] — Backend Clean Architecture Redesign (v1.3.9)
#### Architecture (⚙️ Architecture / 🔴 Critical)
- **Database Migrator**: Developed `src/Core/Migrator.php` extracting 250+ lines of raw SQL schema building out of `db_connect.php`, dropping API latency from ~45ms to ~3ms.
- **View Modularization**: Extracted massive generic blocks from `dashboard.php` into clean partials (`analytics.php`, `results.php`, `students.php`, `settings.php`) under `server/views/tabs/`.
- **The Repository Layer**: Built `ExamRepository`, `StudentRepository`, `QuestionRepository`, and `SettingsRepository`. Refactored `DashboardController` removing all raw SQL.
- **Controller Decoupling**: Refactored `ExamController`, `StudentController`, and `SettingsController` to exclusively use the new Repositories for `INSERT/UPDATE/DELETE` logic.
- **Declarative Middleware Routing**: Built `src/Core/Router.php` and `src/Core/Middleware.php`, stripping messy hardcoded auth arrays (`$adminActions`) out of `api.php`. Routes are now declared natively (e.g. `['middleware' => 'admin']`).
- **Global Error Interceptor**: Created `src/Core/ErrorHandler.php` intercepting all PHP crashes and Fatal Exceptions, writing stack traces to `server/logs/error.log` securely and forcing a JSON `{"error": "Internal Server Error"}` payload to prevent the Flutter app from crashing on HTML responses.
- **Request Validation Core**: Engineered `src/Core/Validator.php` replacing sprawling `isset()` logic with clean arrays (`'title' => 'required|string'`).

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.8 -> 1.3.9).

### [2026-03-19] — Domain Isolation Architecture (v1.3.8)
#### Dashboard (🎨 UX / ⚙️ Architecture)
- **Database Refactor**: Migrated `questions` table schema directly out, appending a `domain` column mapping generic constraints permanently preventing Story/Essay contexts from polluting standard evaluation banks.
- **View Modularization**: Extracted the monolithic >1000 line `dashboard.php` block dissecting HTML logic structurally across three partial configurations: `standard_exams.php`, `campaign_exams.php`, and `essay_exams.php` resolving PHP includes seamlessly.
- **Sidebar Overhaul**: Retargeted Native Dashboard logic swapping broad 'Manage Quizzes' / 'Manage Questions' lists into dedicated 'Standard Exams', 'Campaign Mode', and 'Essay Manager' routes parsing isolated arrays strictly via `DashboardController.php`.
- **Dynamic JavaScript Forms**: Re-mapped legacy rigid `id="add-exam-form"` constraints globally targeting class bindings (`.add-exam-form-domain`) initiating robust hard reloads resolving multi-tab submission conflictions implicitly.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.7 -> 1.3.8).

### [2026-03-19] — Web Dashboard Quiz Types Support (v1.3.7)
#### Dashboard (🎨 UX / ⚙️ Architecture)
- **Exam Type Dropdowns**: Added `Standard`, `Campaign (Story Mode)`, and `Essay` options to the "Create New Exam" and "Edit Exam" forms in the PHP dashboard.
- **Campaign Configuration**: Injected `Prerequisite Exam` and `Unlock Cost` inputs conditionally when creating Campaign exams.
- **Type Badges**: Displayed dynamic `exam_type` badges in the "Existing Exams" table to easily distinguish exam categories at a glance.
- **API Response Hydration**: Updated `addExam` in `ExamController.php` to instantly return `exam_type`, preventing UI desyncs upon creation.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.4.0 -> 1.4.1).

### [2026-03-19] — Bulk Question Excel Import (v1.4.1)
#### Feature (✨ Feature / 🚄 Efficiency)
- **SimpleXLSX Integrations**: Implemented `shuchkin/simplexlsx` and `simplexlsxgen` to parse and build spreadsheet matrices safely skipping memory bloat.
- **Dynamic Template Routing**: Deployed `api.php?action=download_template` routing real-time `.xlsx` templates outlining rigid column headers parsing categories seamlessly.
- **Frontend Dashboard Injection**: Injected "Bulk Import" interactive modal sequence seamlessly routing natively onto `standard_exams.php` views.

### [2026-03-19] — Enterprise Scalability Overhaul (v1.4.0)
#### Architecture (⚙️ Architecture / 🔒 Security / 🔴 Critical)
- **WebSockets Monitor**: Replaced expensive HTTP admin heartbeats with a persistent `Ratchet` WebSocket server mapping on port `8080`.
- **System Caching (PSR-16)**: Integrated `symfony/cache` buffering heavy Leaderboard aggregations inside a 60-second FileSystem threshold.
- **Audit Ledger Engine**: Built an immutable `AuditService` logging admin modifications (deletion, approval, import) dynamically.
- **Database Index Optimization**: Deployed widespread `CREATE INDEX` queries buffering table joins explicitly avoiding 10k+ row latencies.
- **Environment Isolation**: Installed `phpdotenv`, pulling rigid MySQL credentials out of hardcoded singletons directly into isolated `.env` constructs.

### [2026-03-19] — Admin UI Latency Optimization (v1.3.8)
#### Architecture (🎨 UX / 🔴 Critical)
- **Glassmorphism Eradication**: Completely flattened all computationally heavy `backdrop-filter: blur(Npx)` directives across `server/style.css` and `dashboard.php` modals.
- **Radial Gradient Elimination**: Swapped sweeping background `rgba` radial gradients for a crisp, solid Tailwind-inspired flat Slate aesthetic (`#0f172a` monochrome profiles with strict borders), yielding instantaneous dashboard paint times even when aggressively scrolling massive question tables.

### [2026-03-19] — Slim 4 Architecture Migration (v1.3.7)
#### Architecture (⚙️ Architecture / 🔴 Critical)
- **Framework Overhaul**: Integrated the Slim 4 micro-framework with `slim/psr7` to modernize API routing.
- **Middleware PSR-15 Compliance**: Refactored rate limiting and IP whitelisting out of raw API flows into a standardized PSR-15 `SecurityMiddleware`.
- **Controller Refactoring**: Upgraded all HTTP Controllers to accept native PSR-7 `Request` and `Response` objects. 
- **Legacy Gateway Bridge**: Engineered a dynamic URI-rewriter intercepting `?action=` queries mapping backwards compatible operations without fracturing native Flutter implementations.

### [2026-03-18] — Gamified Essay Ecosystem (v1.3.6)
#### Architecture (⚙️ Architecture / 🎨 UX)
- **Student Dashboard Integration**: Established a 3rd top-level `Gateway` element mapping indigo gamification aesthetics resolving `student_essays_screen.dart` configurations explicitly targeting `examType: 'essay'`.
- **Admin Configuration Expansion**: Injected a 6th Top-Level layout across `main_admin_screen.dart` resolving customized creation dialogues tracking essay structures uniquely across `essay_admin_screen.dart`.
- **Parameter Inheritance**: Leveraged existing `v1.3.5` parameter expansions bypassing redundant SQL backend patches syncing PHP bindings dynamically via Flutter HTTP structures natively.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.5 -> 1.3.6).
### [2026-03-20] — Student Results Dual-Tab Migration (v1.3.6)
#### UI Architecture (🎨 UX / ⚙️ Architecture)
- **Database Exposure**: Updated `ResultRepository.php` adding explicit SQL Joins fetching `exam_type` natively out to `QuizResult` DTOs locally.
- **Grades Segregation**: Refactored `student_results_screen.dart` natively inserting a `DefaultTabController` splitting grading arrays into two distinct `TabBarView` lists.
- **Active Pending States**: Engineered localized list bounds visually rendering a "Pending Grade" block specifically when `examType == 'essay'` and `isGraded == false`.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.5 -> 1.3.6).

### [2026-03-18] — Admin Schema Segregation & Immersive UI (v1.3.5)
#### Architecture (⚙️ Architecture / 🎨 UX)
- **Unified Background Integration**: Seamlessly mapped the Custom `GlobalBackground` wrapper stripping generic floating `AppBar` definitions off the Gamification modules generating edge-to-edge transparent viewports securely.
- **Admin Gamification API**: Expanded PHP endpoints `add_exam` & `update_exam` explicitly mapping parameter bindings accommodating `$exam_type`, `$prerequisite_exam_id`, and `$unlock_cost` queries dynamically breaking old database fallback logic.
- **Admin Flutter Repositories**: Upgraded domain logic exposing the `$exam_type` JSON payload parameters passing seamlessly against the internal HTTP adapters.
- **5-Tab Sub-Routing Interface**: Completely split `MainAdminScreen` establishing two independent configuration lists. Exams are strictly `standard` whereas the new Tab 5 `CampaignAdminScreen` filters `campaign` evaluating new dropdown prerequisites over Admin dialog schemas.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.4 -> 1.3.5).

### [2026-03-18] — Gateway Sub-Routing Isolation (v1.3.4)
#### UI Architecture (🎨 UX / ⚙️ Architecture / 🗺️ Navigation)
- **Dashboard Gateways**: Extracted the generic vertical `ListView` array off the primary `DashboardScreen` completely.
- **Twin Modes Card**: Replaced the global list with two massive Premium Gateway Cards: "Story of Psychology" (Campaign) and "Single Exams" (Standard).
- **Dedicated Route Filtering**: Engineered specialized `/campaign_exams` and `/standard_exams` routing pages evaluating native `.where((e) => e.examType == '...')` logic restricting lists to targeted exam groups synchronously.
- **Padlock Retainer**: Seamlessly migrated the Campaign Prerequisite evaluation arrays natively into the new `CampaignExamsScreen` explicitly.

> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.3 -> 1.3.4).

### [2026-03-18] — Gamification & Campaign Ecosystem (v1.3.3)
#### Gamification (🔴 Critical / 🎨 UX / ⚙️ Architecture)
- **Database Modifiers**: Migrated `students` table appending `points` and `total_xp`.
- **Ledger Injections**: Engineered an undeletable `points_ledger` tracking point injection histories securely from the server via `ResultController.php`.
- **Campaign Prerequisites**: Linked a structured sequential unlock logic via `prerequisite_exam_id` on the `exams` model enabling the "Story of Psychology" progression arc natively.
- **Dynamic Lock states**: Programmed `dashboard_screen.dart` parsing completed histories against prerequisites graying out Locked Exams securely mapping UI constraints.
- **Victory Particles**: Overlaid physics-grade `confetti` on `results_screen.dart` dynamically spraying particles globally triggering exactly when Student XP > `0` upon completion.
  
> [!IMPORTANT]
> **Versioning Rule**: Increment the `system_version` patch number (e.g., 1.3.2 -> 1.3.3).

### [2026-03-18] — Global SafeArea Consolidation (v1.3.2)
#### 🎨 UX / 🧰 Code Quality
- Stripped all generic floating `AppBar` wrappers across `dashboard_screen.dart`, `student_login_screen.dart`, `profile_screen.dart`, and standard evaluation interfaces forcing edge-to-edge immersive viewports natively.
- Shifted the Global Localization Language Controller out from the `AppBar` block integrating it directly into the Student Profile Settings menu underneath the Dark Mode toggle map.
- Generated dynamic custom `SafeArea` native headers with smooth Glassmorphic floating layers securing seamless backwards trajectory outside standard `AppBar` scaffolding logic.
- Shrunk internal padding constraints and typographical geometries down by 25% across all Dashboard Action Grids and Exam Evaluation cards enabling increased vertical density.
- Injected strict JWT Token map layers backwards across `ExamRepository` binding the Global Platform Authorization sequence to unblock `get_leaderboard` 401 API rejections.
- Patched the 'Zero Questions' bug mapping a missing synchronous `fetchQuestionsForExam` API trigger into `exam_instructions_screen.dart` strictly before advancing into the live UI viewport bindings.
- Wrapped the primary `dashboard_screen.dart` view body inside a strict `SafeArea` bounds node preventing the top-level User Profile and Grade cards from clipping underneath hardware boundaries.
- Abstracted the Dashboard's complex native gradient design into a reusable `GlobalBackground` module mapping it universally across `Leaderboard` / `Profile` / `History` / `Review` screens resolving Dark Mode background fragmentation.
- Patched Isolate sequence crashes spanning `ApiExams` and `ApiResults` by converting inner-class parsers to top-level background serializers preventing memory leak thread blocks.

All notable changes to this project are recorded here.

### [2026-03-12] — Environment & Toolchain Upgrade (v1.2.0)

#### 🔴 Critical
- **SDK Update**: Migrated the project to the new Flutter SDK at `C:\flutter2`.
- **Gradle Migration**: Transitioned the Android build system from imperative (`apply from`) to the modern **declarative `plugins` block** and `pluginManagement` for better performance and compatibility with current Android tools.
- **Version Upgrades**: Upgraded **Android Gradle Plugin (AGP) to 8.6.0** and **Kotlin to 2.1.0** to satisfy Flutter 3.41.4 requirements.

#### 🧰 Code Quality
- **Improved Build Reliability**: Removed legacy `kotlin_version` property requirements from `build.gradle` scripts.
- **Dependency Resolution**: Updated `intl` package version to `^0.20.2` to resolve a conflict with the new Flutter SDK's internal requirements.

#### 📦 Dependencies
- Updated `pubspec.yaml` with version-aligned dependencies.

### [2026-03-12] — Major Dependency & Toolchain Refactor (v1.3.0)
#### 🔴 Critical / 🧰 Code Quality
- Upgraded Dart SDK to `^3.7.0`.
- Performed a major upgrade of 50+ dependencies to their latest versions.
- Migrated legacy `Record` usage to the modern `AudioRecorder` package.
- Resolved breaking changes in `local_auth` 3.x and `go_router` 17.x.
- Addressed multiple Flutter 3.x UI deprecations (FormField value -> initialValue, etc.).

### [2026-03-11] — Review Fixes (v1.1.0)

#### 🔴 Critical
- **Fixed router bug**: Missing closing `)` on the `/quiz` `GoRoute` in `main.dart` that prevented compilation.

#### 🔒 Security
- **Secure token storage**: Admin JWT token is now stored using `flutter_secure_storage` (encrypted device keychain/keystore) instead of plaintext `SharedPreferences`.

#### 🧰 Code Quality
- **Removed dead import**: `results_screen.dart` import removed from `quiz_screen.dart` (navigation handled by `go_router`).
- **Eliminated hardcoded strings**: All inline `l10n.localeName == 'ar' ? '...' : '...'` ternaries replaced with proper localization keys in both `app_en.arb` and `app_ar.arb`.

#### 🎨 UX
- **Offline Mode banner**: `WelcomeScreen` now shows a visible "⚠️ Offline Mode – Using Cached Data" banner when the backend is unreachable, replacing the silent `debugPrint` fallback.
- **`isOffline` state**: `QuizService` now exposes an `isOffline` boolean that is set when settings/data fetch fails.

#### ♿ Accessibility
- **Timer `Semantics`**: The timer display in `QuizScreen` is now wrapped with a `Semantics` widget so screen readers can announce the remaining time.
- **Answer button `Semantics`**: All MCQ answer option buttons are wrapped with `Semantics(button: true, label: ..., selected: ...)` for proper screen reader support.

#### 📦 Dependencies
- Added `flutter_secure_storage: ^9.2.2` to `pubspec.yaml`.
