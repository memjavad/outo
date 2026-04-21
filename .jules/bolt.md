## 2024-06-03 - Native PHP Array Operations for O(1) Lookups vs Iteration
**Learning:** Replacing user-land `foreach` loops with C-implemented PHP native array functions (`array_count_values`, `array_column`) is highly effective for reducing execution time.
**Action:** When aggregating or transforming large datasets in PHP memory, prioritize using built-in array functions (if side-effects like `null` handling are properly managed upstream, such as via `COALESCE` in SQL).

## 2024-06-03 - Database Aggregation Scope Leaks
**Learning:** When moving logic from PHP memory down to the database using `GROUP BY`, you must mirror the exact scope of the original dataset. Removing `WHERE` clauses will accidentally aggregate the entire database, breaking logic and leaking data.
**Action:** Always verify that aggregate SQL queries (e.g., `SELECT COUNT(*)`) include the same constraints as the queries that populated the original in-memory data structures.
