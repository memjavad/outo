## 2025-02-20 - SQL Injection via unvalidated array keys in Repositories
**Vulnerability:** SQL Injection in `ExamRepository`, `QuestionRepository`, and `StudentRepository` where input array keys were directly concatenated into `INSERT` and `UPDATE` statements without validation, allowing subquery injection or malicious column insertions.
**Learning:** PDO prepared statements only protect parameter values, not column names. Dynamically generating queries from array keys without an explicit allowlist or strict validation exposes the application to SQL injection.
**Prevention:** Always strictly validate array keys (e.g., using a regex like `/^[a-zA-Z0-9_]+$/`) or compare them against a predefined schema allowlist before building `UPDATE` or `INSERT` SQL strings dynamically.
