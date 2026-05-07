## 2024-05-24 - [Hardcoded Secrets]\n**Vulnerability:** Hardcoded DB credentials and JWT secret in config\n**Learning:** Credentials were left in code instead of strictly loading from environment variables or enforcing .env existence.\n**Prevention:** Throw an error when secrets are missing instead of falling back to insecure hardcoded defaults.

## 2024-05-24 - [SSRF & Path Traversal]
**Vulnerability:** `seed_api.php` fetched data payloads from user-provided URLs/paths without any validation or domain restrictions, combined with insecure stream contexts (SSL verification disabled).
**Learning:** Functions like `file_get_contents` are extremely dangerous when parsing user-provided paths without boundaries. Trusting arbitrary inputs enables SSRF (Server-Side Request Forgery) to internal networks or Path Traversal out to system files like `/etc/passwd`.
**Prevention:** Strictly validate external requests by checking `parse_url($url)['host']` against an explicit whitelist of trusted domains. When parsing local file paths, explicitly reject traversal patterns like `..` and ensure errors do not leak the absolute filesystem path back to the user.
