# Student Quiz Platform - Usage Guide

This guide provides comprehensive instructions for both students taking exams and administrators managing the platform.

---

## 👨‍🎓 For Students: Taking an Exam

### 1. Joining an Exam
- **Open the App**: Launch the application on your mobile device or web browser.
- **Enter Name**: Provide your full name.
- **Access Code**: Enter the unique access code provided by your instructor for the specific exam.
- **Join**: Tap the "Join Exam" button. The app will fetch exam data and prepare the session.

### 2. During the Exam
- **Answering Questions**: Read each question carefully and select your answer. Use the "Next" and "Back" buttons to navigate between questions.
- **Timer**: Keep an eye on the countdown timer at the top. The exam will auto-submit when the timer reaches zero.
- **Security Features**:
    - **Anti-Cheating**: On mobile, the app prevents screen recording and screenshots.
    - **Audio Monitoring**: Some exams may record audio during the session to ensure academic integrity.
- **Offline Support**: If you lose your internet connection, the app will display a warning. You can continue answering, and your progress will be synced once you are back online.

### 3. Submitting the Exam
- **Final Review**: Ensure you have answered all questions.
- **Finish**: Tap the "Submit" button on the final question.
- **Results**: You will immediately see your score and can review your answers to see which were correct.

---

## 🔐 For Administrators: Managing the Platform

### 1. Admin Login
- Access the Admin Login screen by navigating to the designated URL or tapping the Admin Login button on the welcome screen.
- Enter your admin credentials (email and password).

### 2. Question Bank (`Dashboard`)
- **View All**: See a list of all existing questions.
- **Search & Filter**: Quickly find questions using the search bar or filtering by type (Multiple Choice, True/False, etc.).
- **Add Question**: Tap the "+" button to create a new question. Specify the question text, options, and the correct answer.
- **Edit/Delete**: Swipe or tap the icons on any question card to modify or remove it.

### 3. Exam Management (`Exams`)
- **Create Exams**: Set up new exam sessions. Define titles, descriptions, and durations.
- **Manage Status**: Activate or deactivate exams to control student access.

### 4. Live Monitoring (`Live Monitor`)
- **Real-time Oversight**: Monitor active student sessions.
- **Tracking Progress**: See which students are currently taking which exams and their progress in real-time.

---

## 🚀 Installation & Setup

### 1. Prerequisites
- **Flutter SDK**: Install Flutter 3.19.0 or higher. (In this environment: `C:\flutter2`).
- **Android SDK**: Required for APK builds. Ensure `ANDROID_HOME` is set.
- **Java**: Java 17 or 21 is required for the latest Gradle build (Gradle 8.7).

### 2. Getting the Code
```bash
git clone <repository-url>
cd "outo platfrom"
```

### 3. Initialize Project
```bash
# Install dependencies
flutter pub get

# Generate localizations (ARB files to Dart code)
flutter gen-l10n
```

---

## ⚙️ Configuration Guide

### 1. API Endpoint
The app connects to a backend server. To change the target server:
- Open `lib/services/app_config.dart`.
- Modify the `productionHost` or `developmentHost` variables to point to your API (e.g., `https://api.yourdomain.com`).

### 2. Android Configuration
- **SDK Paths**: Defined in `android/local.properties`. Ensure `sdk.dir` and `flutter.sdk` are correct.
- **App ID**: If you need to change the package name (currently `com.example.student_quiz_app`), update `applicationId` in `android/app/build.gradle`.
- **Permissions**: Audio recording and network permissions are already configured in `AndroidManifest.xml`.

### 3. Localization
The app is bilingual (EN/AR).
- **Adding Strings**: Edit `lib/l10n/app_en.arb` or `lib/l10n/app_ar.arb`.
- **Applying Changes**: Run `flutter gen-l10n` after every edit to the `.arb` files.

---

## 🛠️ Developer & Deployment Instructions

### Environment Setup
- **Flutter SDK**: Use version `3.x` (located at `C:\flutter2` in this specific setup).
- **Dependencies**: Run `flutter pub get` to install all required packages.
- **L10n**: Generate localizations using `flutter gen-l10n`.

### Build Commands
- **Run Locally (Chrome)**: `& "C:\flutter2\bin\flutter.bat" run -d chrome`
- **Build APK (Android)**: `& "C:\flutter2\bin\flutter.bat" build apk --release`
- **Build Web**: `& "C:\flutter2\bin\flutter.bat" build web`

### Fast Offline Build
If you have a slow or no internet connection, use the specialized offline build script. This skips network-based dependency checks and Gradle updates:
1. **Open PowerShell** in the project directory.
2. **Run the script**:
   ```powershell
   ./build_offline.ps1
   ```
> [!NOTE]
> This requires you to have run a standard build at least once with internet access to cache the initial dependencies.

### Troubleshooting
- **IDE Errors ("Future isn't a type")**: If your editor shows core Dart types as missing, restart your Dart Analysis Server or the editor itself.
- **Android Build Fails**: Ensure your Java version (recommended Java 17 or 21) is compatible with the Gradle version (currently set to 8.7).
