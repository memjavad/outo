<?php
/**
 * Async AI Essay Grader Cron Job
 * Run this script via scheduled tasks (e.g., every 5-10 minutes)
 * `php server/cron/grade_essays.php`
 */

require_once __DIR__ . '/../vendor/autoload.php';

use App\Core\Database;
use App\Repositories\EssayRepository;
use App\Services\AiGradingService;

try {
    $db = Database::getInstance();
} catch (Exception $e) {
    echo "Cron [grade_essays]: Database connection failed. " . $e->getMessage() . "\n";
    exit;
}

// 1. Fetch AI Settings
$stmt = $db->query("SELECT setting_key, setting_value FROM settings WHERE setting_key IN ('ai_api_key', 'ai_model')");
$settings = [];
while ($row = $stmt->fetch(\PDO::FETCH_ASSOC)) {
    $settings[$row['setting_key']] = $row['setting_value'];
}

$apiKey = $settings['ai_api_key'] ?? '';
$model = $settings['ai_model'] ?? 'gemini-3.0-flash';

if (empty($apiKey)) {
    echo "Cron [grade_essays]: No AI API Key configured. Exiting.\n";
    exit;
}

// 2. Find pending essays whose scheduled time has passed
$query = "
    SELECT r.*, e.rubric, e.grading_type 
    FROM essay_results r 
    JOIN exams e ON r.exam_id = e.id 
    WHERE r.is_graded = 0 
    AND (r.scheduled_grading_time IS NULL OR r.scheduled_grading_time <= NOW())
    ORDER BY r.created_at ASC
";

$stmt = $db->query($query);
$pendingEssays = $stmt->fetchAll(\PDO::FETCH_ASSOC);

if (empty($pendingEssays)) {
    echo "Cron [grade_essays]: No pending essays within the scheduled window. Exiting.\n";
    exit;
}

echo "Cron [grade_essays]: Found " . count($pendingEssays) . " pending essays to grade natively...\n";

// 3. Initialize Evaluators
$aiService = new AiGradingService($apiKey, $model);
$essayRepo = new EssayRepository($db);

// 4. Run Evaluations
foreach ($pendingEssays as $essay) {
    echo " -> Evaluating Essay ID: {$essay['id']} [{$essay['student_name']}]...\n";
    
    $rubric = $essay['rubric'] ?? 'No specific rubric provided. Evaluate this answer comprehensively prioritizing accuracy.';
    $gradingType = $essay['grading_type'] ?? 'percentage';
    
    $result = $aiService->gradeSingleEssay($essay, $rubric, $gradingType);
    
    if ($result !== null) {
        $essayRepo->gradeEssay(
            (int)$essay['id'], 
            (float)$result['score_percentage'], 
            $result['grade'], 
            $result['feedback']
        );
        echo "    SUCCESS: Scored {$result['score_percentage']}% ({$result['grade']})\n";
    } else {
        echo "    FAILED: AI Evaluator returned a null payload.\n";
    }
    
    // Slight pause neutralizing rigid API rate limits implicitly
    sleep(2);
}

echo "Cron [grade_essays]: Execution completed successfully.\n";
