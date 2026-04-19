<?php
// C:\the ai\outo platfrom\psychology\seed_campaign_db.php

// Ensure this is run from CLI for safety and timeout limits
if (php_sapi_name() !== 'cli') {
    die("This script can only be executed via the command line.\n");
}

// Adjust memory limit and timeout for massive data insertion
ini_set('memory_limit', '512M');
ini_set('max_execution_time', 0); // No timeout

// ==========================================
// VPS PRODUCTION CONFIGURATION
// ==========================================
// If uploading to a VPS, configure these credentials. You do not need the rest of the backend!
$db_host = 'localhost';
$db_user = 'root'; // Change if your VPS uses a specific user
$db_pass = '';     // Change if your VPS has a password
$db_name = 'student_quiz_app'; // Change if your VPS DB name differs

$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
$conn->set_charset("utf8mb4");

if ($conn->connect_error) {
    die("VPS Database Connection failed: " . $conn->connect_error . "\n");
}

$jsonFilePath = __DIR__ . '/campaign_data.json';

if (!file_exists($jsonFilePath)) {
    die("Error: campaign_data.json not found. Run the Python generator first.\n");
}

$jsonData = file_get_contents($jsonFilePath);
$campaigns = json_decode($jsonData, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    die("Error parsing JSON data: " . json_last_error_msg() . "\n");
}

echo "Found " . count($campaigns) . " levels to seed.\n";

$conn->begin_transaction();

try {
    $previousExamId = null;
    $totalExams = 0;
    $totalQuestions = 0;
    $totalOptions = 0;

    foreach ($campaigns as $level) {
        $levelTitle = isset($level['level_title']) ? $level['level_title'] : ("Level " . $level['level_order']);
        $questions = isset($level['questions']) ? $level['questions'] : [];

        // Insert the exam (Level)
        $stmtExam = $conn->prepare("INSERT INTO exams (title, description, duration_minutes, created_by, status, created_at, exam_type, prerequisite_exam_id, pass_percentage, max_attempts) VALUES (?, ?, ?, ?, ?, NOW(), ?, ?, ?, ?)");
        
        $desc = "Campaign mission generated from General Psychology text.";
        $duration = 10; // 10 minutes for 20 questions
        $createdBy = 1; // Assuming Admin ID is 1
        $status = 'published';
        $examType = 'campaign';
        $levelOrder = isset($level['level_order']) ? (int)$level['level_order'] : 1;
        $passPercentage = ($levelOrder > 50) ? 60 : 50; // Adaptive difficulty to pass
        $maxAttempts = 0; // Infinite attempts in campaign mode

        $stmtExam->bind_param("ssiissiii", $levelTitle, $desc, $duration, $createdBy, $status, $examType, $previousExamId, $passPercentage, $maxAttempts);
        $stmtExam->execute();
        
        $currentExamId = $conn->insert_id;
        $totalExams++;

        // Important: Link this level as the prerequisite for the next level in the sequence!
        $previousExamId = $currentExamId;

        // Insert Questions
        $stmtQuestion = $conn->prepare("INSERT INTO questions (exam_id, question_text, question_type, created_at) VALUES (?, ?, 'mcq', NOW())");
        $stmtOption = $conn->prepare("INSERT INTO options (question_id, option_text, is_correct) VALUES (?, ?, ?)");

        foreach ($questions as $q) {
            if (!isset($q['question_text']) || empty($q['options'])) {
                continue; // Skip malformed
            }

            $qText = $q['question_text'];
            $stmtQuestion->bind_param("is", $currentExamId, $qText);
            $stmtQuestion->execute();
            $questionId = $conn->insert_id;
            $totalQuestions++;

            foreach ($q['options'] as $opt) {
                $oText = $opt['option_text'];
                $isCorrect = (int)$opt['is_correct'];
                $stmtOption->bind_param("isi", $questionId, $oText, $isCorrect);
                $stmtOption->execute();
                $totalOptions++;
            }
        }
        
        echo "Successfully seeded Level {$level['level_order']}: {$levelTitle} (ID: {$currentExamId})\n";
    }

    $conn->commit();
    echo "\n------ SEEDING COMPLETE ------\n";
    echo "Total Exams Inserted: {$totalExams}\n";
    echo "Total Questions Inserted: {$totalQuestions}\n";
    echo "Total Options Inserted: {$totalOptions}\n";

} catch (Exception $e) {
    $conn->rollback();
    echo "Database Transaction Failed. Rolled back changes. Error: " . $e->getMessage() . "\n";
}

$conn->close();
?>
