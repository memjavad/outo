## 2024-05-24 - [Hardcoded Secrets]\n**Vulnerability:** Hardcoded DB credentials and JWT secret in config\n**Learning:** Credentials were left in code instead of strictly loading from environment variables or enforcing .env existence.\n**Prevention:** Throw an error when secrets are missing instead of falling back to insecure hardcoded defaults.

## 2026-04-25 - [SSRF and LFI in API Seeding]
**Vulnerability:** Server-Side Request Forgery and Local File Inclusion in `seed_api.php`
**Learning:** Input parameters specifying URLs or local paths for file fetches were insufficiently validated, allowing an attacker to request arbitrary internal/external resources or traverse local directories.
**Prevention:** Strict domain whitelisting (using `parse_url`) should be enforced for remote fetches. Path traversal sequences (`..`) must be explicitly blocked for local file reads.
