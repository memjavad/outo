## 2026-04-21 - [Screen Recording Code Removal]
**Learning:** Found several commented out lines dealing with FlutterScreenRecording that cluttered quiz_screen.dart. Using basic string deletion via sed is robust for these simple unused variable / dead code removals.
**Action:** When finding dead comment blocks related to outdated dependencies (like ScreenRecording), remove them safely to reduce file bloat.
