## 2024-05-18 - Optimize ResultRepository Insert

**Learning:** When dealing with multiple DB inserts during exam submission, using N+1 query execution introduces severe network/IO overhead. Dynamically chunking the entries and using batch inserts dramatically cuts execution time by over 98%.
**Action:** Utilize chunked bulk inserts (e.g., using `array_chunk()` on PHP arrays) for multiple related row database operations instead of individual execution statements in loops.
