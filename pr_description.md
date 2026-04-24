🧹 Remove unused local variable quizService

🎯 **What:** Removed the unused local variable `quizService` in `lib/presentation/screens/quiz_screen.dart` at line 280 (inside `didChangeAppLifecycleState`).
💡 **Why:** The variable was instantiated but never used. Removing dead code improves maintainability and satisfies Dart analyzer checks.
✅ **Verification:** Used `flutter analyze` to ensure the unused variable warning was resolved and that no other parts of the widget's lifecycle relied on it.
✨ **Result:** Cleaned up the codebase without modifying behavior or functionality.
