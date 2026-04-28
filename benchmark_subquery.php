<?php
require_once __DIR__ . '/server/vendor/autoload.php';

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$pdo->exec("CREATE TABLE exams (id INTEGER PRIMARY KEY, title TEXT, exam_type TEXT, grading_type TEXT)");
$pdo->exec("CREATE TABLE students (id INTEGER PRIMARY KEY, name TEXT)");
$pdo->exec("CREATE TABLE essay_results (id INTEGER PRIMARY KEY, exam_id INTEGER, student_id INTEGER, student_name TEXT, answers_json TEXT, is_graded INTEGER, score_percentage REAL, grade TEXT, created_at DATETIME)");

$pdo->exec("INSERT INTO exams (title, exam_type, grading_type) VALUES ('Test Essay Exam 1', 'essay', 'percentage')");

$pdo->exec("INSERT INTO students (name) VALUES ('Test Student')");

$pdo->beginTransaction();
$stmt = $pdo->prepare("INSERT INTO essay_results (exam_id, student_id, student_name, answers_json, is_graded, score_percentage, grade, created_at) VALUES (?, 1, 'Test Student', '{\"1\": \"This is a test essay.\"}', ?, 0, 'F', '2024-05-01 10:00:00')");
for ($i = 0; $i < 50000; $i++) {
    $stmt->execute([1, ($i % 10 === 0) ? 0 : 1]);
}
$pdo->commit();

$startOpt = microtime(true);
$allEssayResultsOpt = $pdo->query("
    SELECT r.*, e.grading_type as exam_grading_type, COALESCE(e.title, 'Unknown Exam') as exam_title, COALESCE(s.name, r.student_name) as student_name
    FROM (
        SELECT * FROM essay_results WHERE is_graded = 0
        UNION
        SELECT * FROM essay_results ORDER BY created_at DESC LIMIT 3000
    ) r
    LEFT JOIN exams e ON r.exam_id = e.id
    LEFT JOIN students s ON r.student_id = s.id
    ORDER BY r.created_at DESC
")->fetchAll(PDO::FETCH_ASSOC);
$endOpt = microtime(true);
echo "UNION limit time: " . ($endOpt - $startOpt) . " seconds.\n";
