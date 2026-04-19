<?php
session_start();
require_once __DIR__ . '/vendor/autoload.php';

use Slim\Factory\AppFactory;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;
use Psr\Http\Message\ResponseInterface as Response;
use App\Core\Database;
use App\Core\ErrorHandler;
use App\Middleware\SecurityMiddleware;
use App\Services\SecurityService;
use App\Repositories\SecurityRepository;
use App\Controllers\{
    AuthController, ExamController, StudentController, 
    SessionController, ResultController, SettingsController, 
    UpdateController, AjaxController, StoreController, AnalyticsController
};

// 1. Initialize Error Handler 
ErrorHandler::register();

// 2. CORS Headers
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
} else {
    header("Access-Control-Allow-Origin: *");
}
header("Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS, PUT");
header("Access-Control-Allow-Headers: Content-Type, X-API-Key, Authorization, X-Requested-With");
header("Access-Control-Allow-Credentials: true");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

// 3. Instantiate Slim App
$app = AppFactory::create();
$app->addBodyParsingMiddleware();
$app->addRoutingMiddleware();

// 4. Legacy Action Rewriting Middleware
// Seamlessly translates Flutter's "?action=student_login" or POST body "action" => "student_login" into native Slim paths like "/student_login"
$app->add(function (Request $request, RequestHandler $handler) {
    if ($request->getMethod() !== 'OPTIONS') {
        $action = $request->getQueryParams()['action'] ?? $request->getQueryParams()['endpoint'] ?? null;
        if (!$action && $request->getMethod() === 'POST') {
            $parsedBody = $request->getParsedBody();
            if (is_array($parsedBody)) {
                $action = $parsedBody['action'] ?? $parsedBody['endpoint'] ?? null;
            }
        }
        
        if ($action) {
            $uri = $request->getUri()->withPath('/' . $action);
            $request = $request->withUri($uri);
        }
    }
    return $handler->handle($request);
});

// 5. Build Global Security Architecture
$pdo = Database::getInstance();
$securityService = new SecurityService(new SecurityRepository($pdo));
$securityMiddleware = new SecurityMiddleware($securityService);

// 6. Native Slim Routing Mapped to Controllers
$app->group('', function (\Slim\Routing\RouteCollectorProxy $group) {
    
    // Auth Routes
    $group->post('/admin_login', [AuthController::class, 'apiLogin']);
    $group->post('/student_login', [StudentController::class, 'loginStudent']);
    $group->post('/student_register', [StudentController::class, 'registerStudent']);
    $group->get('/tg_login', [AuthController::class, 'checkTelegramLogin']); // Needs custom controller map if Flutter sends GET
    $group->get('/check_tg_login', [AuthController::class, 'checkTelegramLogin']);

    // Registration & Profiles
    $group->get('/student_profile', [StudentController::class, 'getProfile']);
    $group->post('/update_student_profile', [StudentController::class, 'updateProfile']);
    
    // Admin Students
    $group->get('/students', [StudentController::class, 'getStudents']);
    $group->post('/add_student', [StudentController::class, 'addStudent']);
    $group->post('/import_students', [StudentController::class, 'bulkImport']);
    $group->get('/pending_students', [StudentController::class, 'getPendingStudents']);
    $group->post('/approve_student', [StudentController::class, 'approveStudent']);
    $group->post('/reject_student', [StudentController::class, 'rejectStudent']);

    // Exams & Questions
    $group->get('/exams', [ExamController::class, 'getExams']);
    $group->post('/add_exam', [ExamController::class, 'addExam']);
    $group->post('/update_exam', [ExamController::class, 'updateExam']);
    $group->delete('/delete_exam', [AjaxController::class, 'deleteItem']); // Mapped delete API
    
    $group->get('/questions', [ExamController::class, 'getQuestions']);
    $group->post('/add_question', [ExamController::class, 'addQuestion']);
    $group->post('/update_question', [ExamController::class, 'updateQuestion']);
    $group->post('/import_questions', [ExamController::class, 'bulkImport']);
    $group->get('/download_template', [ExamController::class, 'downloadTemplate']);
    $group->get('/question_details', [ExamController::class, 'getQuestionDetails']);
    $group->get('/check_access_code', [ExamController::class, 'checkAccessCode']);

    // Sessions & Heartbeat
    $group->post('/start_session', [SessionController::class, 'startSession']);
    $group->post('/heartbeat_session', [SessionController::class, 'heartbeat']);
    $group->get('/live_sessions', [SessionController::class, 'listActive']);

    // Results & Leaderboard
    $group->post('/submit_result', [ResultController::class, 'saveResult']);
    $group->post('/submit_essay_result', [\App\Controllers\EssayController::class, 'saveEssayResult']);
    $group->get('/student_results', [ResultController::class, 'getStudentResults']);
    $group->get('/get_leaderboard', [ResultController::class, 'getLeaderboard']);
    $group->get('/get_campaign_leaderboard', [ResultController::class, 'getCampaignLeaderboard']);
    $group->get('/pending_grading', [\App\Controllers\EssayController::class, 'getPendingEssays']);
    $group->post('/grade_result', [ResultController::class, 'gradeResult']);
    $group->post('/grade_essay', [\App\Controllers\EssayController::class, 'gradeEssay']);
    $group->post('/grade_essay_ai_now', [\App\Controllers\EssayController::class, 'gradeEssayAiNow']);
    $group->post('/clear_results', [ResultController::class, 'clearResults']);

    // Store & Inventory
    $group->get('/store_items', [StoreController::class, 'getItems']);
    $group->post('/buy_item', [StoreController::class, 'buyItem']);
    $group->post('/consume_item', [StoreController::class, 'consumeItem']);

    // Utilities & Admin
    $group->get('/get_exam_kpis', [AnalyticsController::class, 'getExamKpis']);
    $group->get('/get_distractor_analysis', [AnalyticsController::class, 'getDistractorAnalysis']);
    $group->get('/analytics', [AjaxController::class, 'getAnalytics']);
    $group->post('/delete_item', [AjaxController::class, 'deleteItem']);
    $group->get('/settings', [SettingsController::class, 'getSettings']);
    $group->post('/update_settings', [SettingsController::class, 'updateSettings']);
    $group->post('/fix_db', [SettingsController::class, 'fixDatabaseSchema']);
    $group->post('/get_system_logs', [SettingsController::class, 'getSystemLogs']);
    $group->post('/clear_system_logs', [SettingsController::class, 'clearSystemLogs']);
    $group->post('/test_ai_connection', [SettingsController::class, 'testAiConnection']);
    
    $group->post('/update_system', [UpdateController::class, 'upload']);

})->add($securityMiddleware);

// Add custom error handling
$errorMiddleware = $app->addErrorMiddleware(true, true, true);
$errorHandler = $errorMiddleware->getDefaultErrorHandler();
$errorHandler->forceContentType('application/json');

$app->run();
