## 2024-05-19 - [Fix N+1 Query in QuestionRepository]
**Learning:** Found N+1 query issue in `QuestionRepository::getByExamId` and `QuestionRepository::getAll` where options were fetched inside a loop.
**Action:** Replaced the loop with a single query using an `IN (...)` clause to fetch all options for the retrieved questions, and then grouped them by `question_id` in PHP. This improved performance by ~96% in a benchmark test.
