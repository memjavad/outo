<?php
require_once __DIR__ . '/server/vendor/autoload.php';

// Create SQLite in-memory database to simulate DB load
$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Setup schema
$pdo->exec("CREATE TABLE exams (id INTEGER PRIMARY KEY, title TEXT, exam_type TEXT, grading_type TEXT)");
$pdo->exec("CREATE TABLE students (id INTEGER PRIMARY KEY, name TEXT)");
$pdo->exec("CREATE TABLE essay_results (id INTEGER PRIMARY KEY, exam_id INTEGER, student_id INTEGER, student_name TEXT, answers_json TEXT, is_graded INTEGER, score_percentage REAL, grade TEXT, created_at DATETIME)");

// Insert dummy exams
$pdo->exec("INSERT INTO exams (title, exam_type, grading_type) VALUES ('Test Essay Exam 1', 'essay', 'percentage')");
$pdo->exec("INSERT INTO exams (title, exam_type, grading_type) VALUES ('Test Essay Exam 2', 'essay', 'percentage')");

// Insert dummy students
$pdo->exec("INSERT INTO students (name) VALUES ('Test Student')");

// Insert 50,000 essay results
$pdo->beginTransaction();
$stmt = $pdo->prepare("INSERT INTO essay_results (exam_id, student_id, student_name, answers_json, is_graded, score_percentage, grade, created_at) VALUES (?, 1, 'Test Student', '{\"1\": \"This is a test essay.\"}', ?, 0, 'F', '2024-05-01 10:00:00')");
for ($i = 0; $i < 50000; $i++) {
    $examId = ($i % 2) + 1;
    $isGraded = ($i % 10 === 0) ? 0 : 1; // 10% are pending
    $stmt->execute([$examId, $isGraded]);
}
$pdo->commit();

echo "Seeded 50,000 essay results.\n";

// Baseline benchmark
$start = microtime(true);
$allEssayResults = $pdo->query("
   SELECT r.*, e.grading_type as exam_grading_type, COALESCE(e.title, 'Unknown Exam') as exam_title, COALESCE(s.name, r.student_name) as student_name
   FROM essay_results r
   LEFT JOIN exams e ON r.exam_id = e.id
   LEFT JOIN students s ON r.student_id = s.id
   ORDER BY r.created_at DESC
")->fetchAll(PDO::FETCH_ASSOC);

$pendingEssays = array_filter($allEssayResults, fn($r) => $r['is_graded'] == 0);

$essayResultsByExamId = [];
foreach ($allEssayResults as $res) {
    $essayResultsByExamId[$res['exam_id']][] = $res;
}
$end = microtime(true);
$baselineTime = $end - $start;
echo "Baseline time: " . $baselineTime . " seconds.\n";


// Optimized benchmark
$startOpt = microtime(true);

// 1. Fetch pending essays (LIMIT if needed, or just let DB do it)
$pendingEssaysOpt = $pdo->query("
   SELECT r.*, e.grading_type as exam_grading_type, COALESCE(e.title, 'Unknown Exam') as exam_title, COALESCE(s.name, r.student_name) as student_name
   FROM essay_results r
   LEFT JOIN exams e ON r.exam_id = e.id
   LEFT JOIN students s ON r.student_id = s.id
   WHERE r.is_graded = 0
   ORDER BY r.created_at ASC
")->fetchAll(PDO::FETCH_ASSOC);

// 2. We don't fetch all results for essayResultsByExamId up front.
// Instead of fetching all essay results and grouping them in PHP, we will fetch them on-demand via API or only fetch a limited set. Wait, the dashboard tab expects `$essayResultsByExamId`.
$endOpt = microtime(true);
$optTime = $endOpt - $startOpt;
echo "Optimized pending time: " . $optTime . " seconds.\n";
