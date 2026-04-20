## 2024-05-24 - Removed Hardcoded Secrets
**Vulnerability:** Hardcoded database/JWT secrets were found in `server/src/Core/Config.php`.
**Learning:** Storing secrets in source code is a critical vulnerability that can expose sensitive systems and data to unauthorized access.
**Prevention:** Always use environment variables or a secure secrets manager for sensitive information.
