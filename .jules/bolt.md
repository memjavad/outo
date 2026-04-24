
## 2024-05-18 - Bulk Insert Optimization
**Learning:** Inserting rows individually within a loop (N+1 queries) significantly degrades performance, especially in network-bound PHP/MySQL setups like `ExamController::addQuestion` creating options.
**Action:** Always prefer bulk insert strategies (e.g., `createOptionsBulk` using multi-row `VALUES (?, ?), (?, ?)` syntax) over repeated `createOption` calls to minimize database roundtrips and drastically improve execution time.
