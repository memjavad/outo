
## 2024-06-25 - [Optimize DashboardController Grade Distribution]
**Learning:** Optimizing aggregate calculations such as grade distributions by offloading them to the database using `GROUP BY` avoids processing large amounts of result records in memory within PHP.
**Action:** Next time when encountering a loop over database results solely for counting and aggregating, replace it with a `GROUP BY` SQL query.
