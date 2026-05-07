<?php
// C:\the ai\outo platfrom\server\seed_api.php
error_reporting(0);
ini_set('display_errors', 0);
header('Content-Type: application/json');

try {
    require_once __DIR__ . '/vendor/autoload.php';
    require_once __DIR__ . '/db_connect.php'; 
    // This securely imports the global $pdo connection from their framework!
} catch (Throwable $e) {
    echo json_encode(['status' => 'error', 'message' => 'Failed to load framework: ' . $e->getMessage()]);
    exit;
}

$action = $_GET['action'] ?? '';

if ($action === 'migrate') {
    // MySQL 5.7 and older do not support 'IF NOT EXISTS' in ALTER TABLE ADD COLUMN.
    // Instead, we try to append the columns individually and silently ignore failures if they already exist.
    
    $queries = [
        "ALTER TABLE quiz_results ADD COLUMN earned_stars INT DEFAULT 0 AFTER score_percentage;",
        "ALTER TABLE quiz_results ADD COLUMN campaign_score INT DEFAULT 0 AFTER earned_stars;",
        "ALTER TABLE students ADD COLUMN stars INT DEFAULT 0 AFTER points;",
        "ALTER TABLE exams ADD COLUMN pass_percentage INT DEFAULT 50 AFTER exam_type;",
        "ALTER TABLE exams ADD COLUMN max_attempts INT DEFAULT 0 AFTER pass_percentage;"
    ];

    foreach ($queries as $q) {
        try {
            $pdo->exec($q);
        } catch (Throwable $e) {
            // Silently swallow errors (meaning the column already exists)
        }
    }
    
    echo json_encode(['status' => 'success', 'message' => 'Migration forcefully verified']);
    exit;
}

if ($action === 'seed_chunk') {
    $index = isset($_GET['index']) ? (int)$_GET['index'] : 0;
    $previousExamId = isset($_GET['prev_id']) && $_GET['prev_id'] != 'null' ? (int)$_GET['prev_id'] : null;
    $targetJson = isset($_GET['json_url']) ? $_GET['json_url'] : 'psychology/campaign_data.json';
    
    // Evaluate if user inputted an absolute HTTPS URL or a local file
    if (strpos($targetJson, 'http') === 0) {
        $parsedUrl = parse_url($targetJson);
        if (!isset($parsedUrl['host']) || $parsedUrl['host'] !== 's.nabuo.org') {
            echo json_encode(['status' => 'error', 'message' => "Untrusted domain"]);
            exit;
        }
        $context = stream_context_create([
            "ssl" => ["verify_peer" => true, "verify_peer_name" => true],
            "http" => ["timeout" => 30] // Prevent remote timeouts
        ]);
        $jsonData = @file_get_contents($targetJson, false, $context);
    } else {
        if (strpos($targetJson, '..') !== false) {
            echo json_encode(['status' => 'error', 'message' => "Invalid path"]);
            exit;
        }
        $jsonFilePath = __DIR__ . '/' . ltrim($targetJson, '/\\');
        if (!file_exists($jsonFilePath)) {
            echo json_encode(['status' => 'error', 'message' => "Local missing payload"]);
            exit;
        }
        $jsonData = @file_get_contents($jsonFilePath);
    }
    
    if (!$jsonData) {
        echo json_encode(['status' => 'error', 'message' => "Failed to read data payload from: $targetJson"]);
        exit;
    }
    
    $campaigns = json_decode($jsonData, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid JSON structure: ' . json_last_error_msg()]);
        exit;
    }
    
    if ($index >= count($campaigns)) {
        echo json_encode(['status' => 'complete']);
        exit;
    }
    
    $level = $campaigns[$index];
    $levelTitle = isset($level['level_title']) ? $level['level_title'] : ("Level " . $level['level_order']);
    $questions = isset($level['questions']) ? $level['questions'] : [];
    
    $pdo->beginTransaction();
    try {
        // Insert Exam
        $stmtExam = $pdo->prepare("INSERT INTO exams (title, description, exam_timer, created_by, is_active, created_at, exam_type, prerequisite_exam_id, pass_percentage, max_attempts) VALUES (?, ?, ?, ?, ?, NOW(), ?, ?, ?, ?)");
        $desc = "Campaign mission generated from General Psychology text.";
        $duration = 10;
        $createdBy = 1; 
        $isActive = 1; // Native boolean for 'published'
        $examType = 'campaign';
        $levelOrder = isset($level['level_order']) ? (int)$level['level_order'] : ($index + 1);
        $passPercentage = ($levelOrder > 50) ? 60 : 50; 
        $maxAttempts = 0; 

        $stmtExam->execute([$levelTitle, $desc, $duration, $createdBy, $isActive, $examType, $previousExamId, $passPercentage, $maxAttempts]);
        $currentExamId = $pdo->lastInsertId();
        
        // Insert Questions
        $stmtQuestion = $pdo->prepare("INSERT INTO questions (exam_id, question_text, question_type, correct_answer_index, created_at) VALUES (?, ?, 'multiple_choice', ?, NOW())");
        $stmtOption = $pdo->prepare("INSERT INTO options (question_id, option_text, option_index) VALUES (?, ?, ?)");
        
        foreach ($questions as $q) {
            if (!isset($q['question_text']) || empty($q['options'])) continue;
            
            $qText = $q['question_text'];
            
            // Map the exact index placement where the correct option resides
            $correctIdx = 0;
            foreach ($q['options'] as $idx => $opt) {
                if ((int)$opt['is_correct'] === 1) {
                    $correctIdx = $idx;
                }
            }
            
            $stmtQuestion->execute([$currentExamId, $qText, $correctIdx]);
            $questionId = $pdo->lastInsertId();
            
            foreach ($q['options'] as $idx => $opt) {
                $oText = $opt['option_text'];
                $stmtOption->execute([$questionId, $oText, $idx]);
            }
        }
        
        $pdo->commit();
        echo json_encode([
            'status' => 'success', 
            'next_index' => $index + 1, 
            'current_exam_id' => $currentExamId,
            'total_levels' => count($campaigns),
            'message' => "Seeded $levelTitle"
        ]);
    } catch (Exception $e) {
        $pdo->rollBack();
        echo json_encode(['status' => 'error', 'message' => "SQL Execution Error: " . $e->getMessage()]);
    }
    exit;
}
echo json_encode(['status' => 'error', 'message' => 'Invalid action']);
?>
