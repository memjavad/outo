## 2024-05-24 - Production Debug Script Left Enabled
**Vulnerability:** A debug script (`server/debug_prod.php`) was left enabled in the production directory, exposing internal application flow, database connection status, and stack traces to unauthorized visitors.
**Learning:** Debug scripts left in production environments can expose sensitive technical details, aiding attackers in further exploitation.
**Prevention:** Never commit or deploy ad-hoc debug scripts to production. Use secure, authenticated logging systems to trace execution flows in production instead.
