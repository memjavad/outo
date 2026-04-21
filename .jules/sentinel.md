## 2024-05-16 - Unauthenticated Access to System Logs Fix
**Vulnerability:** Insecure Direct Object Reference (IDOR) / Missing Authentication. `server/view_logs.php` exposed sensitive server error logs to anyone with the URL, allowing read access and the ability to clear the logs to cover tracks.
**Learning:** Security checks must be implemented consistently on all files exposed to the web that handle sensitive data, especially those outside of the main routing framework (e.g., standalone utility scripts).
**Prevention:** Always verify `session_start()` and authentication status (e.g., `$_SESSION['admin_logged_in'] === true`) at the top of any PHP script that provides administrative or sensitive functionality before executing any logic or outputting data.
