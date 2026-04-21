## 2026-04-21 - Hardcoded Test Credentials
**Vulnerability:** Test script containing live server URL and hardcoded credentials.
**Learning:** Test scripts with real or stub credentials can expose attack surface or give attackers insights into authentication flows and endpoints if deployed or committed.
**Prevention:** Avoid writing test scripts that contain secrets or direct hits against live production endpoints in the source tree. Use local environment variables or securely mock external calls.
