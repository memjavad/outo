## 2024-05-15 - [Result Service PHPUnit Testing]
**Learning:** Bypassing vendor constraints locally. PHPUnit 10 requires PHP >= 8.4, which causes a mismatch with the system PHP 8.3 during automated workflows.
**Action:** Created custom wrapper and simple testing scripts during development instead of full test runner to assert logic until dependencies resolve.
