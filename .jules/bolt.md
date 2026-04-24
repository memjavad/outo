## 2026-04-23 - [N+1 Queries on Option Insertion]
**Learning:** Inserting options one by one in a loop creates an N+1 query problem, slowing down exam creation and updates.
**Action:** Use a bulk insert method like `createOptionsBulk` to combine multiple options into a single SQL query.
