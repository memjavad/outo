## 2024-05-06 - Fix SSRF and LFI vulnerabilities in server/seed_api.php
**Vulnerability:** The `seed_api.php` file allowed remote HTTP loading without host validation (SSRF) and local file loading without path traversal protection (LFI).
**Learning:** This existed because the unvalidated user input (`$_GET['json_url']`) was passed directly into `@file_get_contents`.
**Prevention:** Always validate URLs against an allowed host list and sanitize local file paths by blocking traversal characters (`..`, `\0`) before reading them.
