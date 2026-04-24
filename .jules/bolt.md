## 2024-04-21 - Eliminate N+1 Query in QuestionRepository
**Learning:** In `QuestionRepository::getAll` and `getByExamId`, fetching options for each question inside a loop resulted in an N+1 query problem, taking ~95ms for 500 questions.
**Action:** Use a batching approach with `IN (...)` queries to fetch options for chunks of questions (e.g., 500 at a time) and group them in memory. This reduces the number of queries drastically, improving performance to ~4ms for 500 questions. Ensure chunking is used to avoid hitting database limits on the number of parameters in an `IN` clause.
