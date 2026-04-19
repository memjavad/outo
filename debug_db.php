<?php
require __DIR__ . '/server/vendor/autoload.php';
require __DIR__ . '/server/src/Core/Config.php';
require __DIR__ . '/server/src/Core/Database.php';

$db = App\Core\Database::getInstance();
$exams = $db->query("SELECT id, title, exam_type FROM exams WHERE exam_type = 'standard'")->fetchAll(PDO::FETCH_ASSOC);

foreach ($exams as $exam) {
    echo "Exam: {$exam['title']} (ID: {$exam['id']})\n";
    $stmt = $db->prepare("SELECT COUNT(*) FROM questions WHERE exam_id = ?");
    $stmt->execute([$exam['id']]);
    $count = $stmt->fetchColumn();
    echo "Questions: {$count}\n";
    
    if ($count > 0) {
        $qStmt = $db->prepare("SELECT id, exam_id, question_type FROM questions WHERE exam_id = ? LIMIT 1");
        $qStmt->execute([$exam['id']]);
        $q = $qStmt->fetch(PDO::FETCH_ASSOC);
        echo "Sample Question ID: {$q['id']}, Type: {$q['question_type']}, ExamID: {$q['exam_id']}\n";
    }
    echo "--------------------------\n";
}
