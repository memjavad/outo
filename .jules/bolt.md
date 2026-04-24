## 2024-04-24 - Bulk option insertion optimization
**Learning:** Found N+1 queries when inserting multiple options via `createOption` inside a loop in `ExamController` and `ExamService`.
**Action:** Use a bulk insertion method `createOptionsBulk` to avoid N+1 query bottlenecks.
