## 2026-04-21 - [PHP N+1 Query Anti-Pattern]
**Learning:** Found a classic N+1 query bottleneck in `server/src/Repositories/QuestionRepository.php` where `getByExamId` and `getAll` methods iterated through questions and ran an individual `SELECT` for each question's options.
**Action:** Always verify loops accessing relational repositories to identify hidden queries. Use `IN` clauses to batch fetch child records in one go and map them in memory to parent IDs to drastically minimize database overhead.
