## 2024-06-25 - Bulk Insert for Options
**Learning:** Inserting rows individually within a loop causes significant N+1 overhead during database operations, notably in ExamController option processing.
**Action:** Always prefer bulk inserts (e.g., `INSERT INTO table (x,y) VALUES (?), (?)`) using bound parameters in PDO for batch operations to optimize performance and lower latency.
