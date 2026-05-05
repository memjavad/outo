## 2024-05-24 - [Hardcoded Secrets]\n**Vulnerability:** Hardcoded DB credentials and JWT secret in config\n**Learning:** Credentials were left in code instead of strictly loading from environment variables or enforcing .env existence.\n**Prevention:** Throw an error when secrets are missing instead of falling back to insecure hardcoded defaults.

## 2024-05-24 - [Hardcoded API Keys]
**Vulnerability:** Hardcoded Gemini API keys found in server/psychology/generate_campaign.py
**Learning:** Keys were left in the codebase which can lead to unauthorized access and quota exhaustion.
**Prevention:** Always use environment variables to load sensitive credentials like API keys.
