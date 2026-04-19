<?php

try {
    $db = new PDO('sqlite:' . __DIR__ . '/database.sqlite');
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Add points to students
    try { $db->exec("ALTER TABLE students ADD COLUMN points INTEGER DEFAULT 0"); } catch (Exception $e) {}
    try { $db->exec("ALTER TABLE students ADD COLUMN total_xp INTEGER DEFAULT 0"); } catch (Exception $e) {}
    
    // Ledger
    $db->exec("CREATE TABLE IF NOT EXISTS points_ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_name TEXT,
        amount INTEGER,
        reason TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )");
    
    // Campaign Mode / Prerequisites for exams
    try { $db->exec("ALTER TABLE exams ADD COLUMN prerequisite_exam_id INTEGER DEFAULT NULL"); } catch (Exception $e) {}
    try { $db->exec("ALTER TABLE exams ADD COLUMN unlock_cost INTEGER DEFAULT 0"); } catch (Exception $e) {}
    try { $db->exec("ALTER TABLE exams ADD COLUMN exam_type TEXT DEFAULT 'standard'"); } catch (Exception $e) {}
    
    echo "Migration completed successfully.\n";
} catch (Exception $e) {
    echo "Fatal Error: " . $e->getMessage() . "\n";
}
