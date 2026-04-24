
## 2024-05-14 - ResultRepository Bulk Insert Optimization
**Learning:** `ResultRepository::createResult` was performing N+1 queries when inserting student responses, leading to severe performance issues.
**Action:** Always prefer chunked bulk inserts (e.g., batched by 100) instead of iterating over arrays and calling `execute` sequentially.
