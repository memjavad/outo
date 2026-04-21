## 2024-05-18 - Information Disclosure via Leftover Debug Scripts
**Vulnerability:** Debug, testing, and migration scripts (`debug_prod.php`, `check_db.php`, `view_logs.php`, etc.) were left in the production web root, exposing sensitive internal data (stack traces, user password hashes, error logs) to any unauthenticated visitor.
**Learning:** Development and debugging tools must never be deployed or left in a production web root.
**Prevention:** Establish a strict deployment pipeline that excludes all test/debug scripts. Remove one-off diagnostic files immediately after use. Ensure `.gitignore` or deployment rules explicitly exclude files like `test_*.php`, `debug_*.php`, etc.
