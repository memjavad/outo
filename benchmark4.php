<?php
require_once __DIR__ . '/server/vendor/autoload.php';

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$pdo->exec("CREATE TABLE exams (id INTEGER PRIMARY KEY, title TEXT, exam_type TEXT, grading_type TEXT)");
$pdo->exec("CREATE TABLE students (id INTEGER PRIMARY KEY, name TEXT)");
$pdo->exec("CREATE TABLE essay_results (id INTEGER PRIMARY KEY, exam_id INTEGER, student_id INTEGER, student_name TEXT, answers_json TEXT, is_graded INTEGER, score_percentage REAL, grade TEXT, created_at DATETIME)");

$pdo->exec("INSERT INTO exams (title, exam_type, grading_type) VALUES ('Test Essay Exam 1', 'essay', 'percentage')");
$pdo->exec("INSERT INTO exams (title, exam_type, grading_type) VALUES ('Test Essay Exam 2', 'essay', 'percentage')");

$pdo->exec("INSERT INTO students (name) VALUES ('Test Student')");

$pdo->beginTransaction();
$stmt = $pdo->prepare("INSERT INTO essay_results (exam_id, student_id, student_name, answers_json, is_graded, score_percentage, grade, created_at) VALUES (?, 1, 'Test Student', '{\"1\": \"This is a test essay.\"}', ?, 0, 'F', '2024-05-01 10:00:00')");
for ($i = 0; $i < 50000; $i++) {
    $examId = ($i % 2) + 1;
    $isGraded = ($i % 10 === 0) ? 0 : 1;
    $stmt->execute([$examId, $isGraded]);
}
$pdo->commit();


$startOpt = microtime(true);
$allEssayResultsOpt = $pdo->query("
    SELECT r.*, e.grading_type as exam_grading_type, COALESCE(e.title, 'Unknown Exam') as exam_title, COALESCE(s.name, r.student_name) as student_name
    FROM essay_results r
    LEFT JOIN exams e ON r.exam_id = e.id
    LEFT JOIN students s ON r.student_id = s.id
    ORDER BY r.created_at DESC
")->fetchAll(PDO::FETCH_ASSOC);

$essayResultsByExamId = [];
$pendingEssays = [];
foreach ($allEssayResultsOpt as $res) {
    if ($res['is_graded'] == 0) {
        $pendingEssays[] = $res;
    }
    // Limit to top 500 per exam to prevent UI bloat
    if (!isset($essayResultsByExamId[$res['exam_id']])) {
        $essayResultsByExamId[$res['exam_id']] = [];
    }
    if (count($essayResultsByExamId[$res['exam_id']]) < 500) {
        $essayResultsByExamId[$res['exam_id']][] = $res;
    }
}
$endOpt = microtime(true);
echo "PHP Limit array logic time: " . ($endOpt - $startOpt) . " seconds.\n";
