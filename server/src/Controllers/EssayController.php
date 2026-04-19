<?php
namespace App\Controllers;

use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;
use App\Core\Database;
use App\Services\EssayService;
use App\Repositories\EssayRepository;

class EssayController extends BaseController {
    
    public function saveEssayResult(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $studentId = $request->getAttribute('student_id');

        if (!$studentId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $db = Database::getInstance();
        $essayService = new EssayService(new EssayRepository($db));
        
        try {
            $data['student_id'] = $studentId; // Securely overwrite student ID from JWT token
            $result = $essayService->saveEssayResult($data);
            return $this->json($response, $result);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to save essay: " . $e->getMessage()], 500);
        }
    }

    public function getPendingEssays(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $db = Database::getInstance();
        $essayService = new EssayService(new EssayRepository($db));
        
        try {
            $results = $essayService->getPendingEssays();
            return $this->json($response, $results);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to fetch pending essays: " . $e->getMessage()], 500);
        }
    }

    public function gradeEssay(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $db = Database::getInstance();
        $essayService = new EssayService(new EssayRepository($db));
        $data = $request->getParsedBody() ?? [];

        try {
            $resultId = (int)($data['id'] ?? 0);
            $scorePct = (float)($data['score_percentage'] ?? 0);
            $grade = $data['grade'] ?? 'Graded';
            $feedback = $data['teacher_feedback'] ?? null;
            $studentIdTarget = (int)($data['student_id'] ?? 0);
            $earnedPoints = (int)($data['earned_points'] ?? 0);

            $result = $essayService->gradeEssay($resultId, $scorePct, $grade, $feedback, $studentIdTarget, $earnedPoints);
            return $this->json($response, $result);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to grade essay: " . $e->getMessage()], 500);
        }
    }

    public function gradeEssayAiNow(Request $request, Response $response, array $args): Response {
        file_put_contents(__DIR__ . '/../../ai_debug.log', "HIT ENDPOINT: gradeEssayAiNow at " . date('Y-m-d H:i:s') . "\n", FILE_APPEND);
        
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $db = Database::getInstance();
        $data = $request->getParsedBody() ?? [];
        $resultId = (int)($data['result_id'] ?? 0);
        
        if (!$resultId) {
            return $this->json($response, ["error" => "Missing result ID"], 400);
        }

        try {
            $stmt = $db->prepare("
                SELECT er.*, e.rubric, e.grading_type 
                FROM essay_results er 
                JOIN exams e ON er.exam_id = e.id 
                WHERE er.id = ? AND er.is_graded = 0
            ");
            $stmt->execute([$resultId]);
            $essay = $stmt->fetch(\PDO::FETCH_ASSOC);

            if (!$essay) {
                return $this->json($response, ["error" => "Essay not found or already graded."], 404);
            }

            $stmtSet = $db->query("SELECT setting_key, setting_value FROM settings WHERE setting_key IN ('ai_api_key', 'ai_model')");
            $settings = $stmtSet->fetchAll(\PDO::FETCH_KEY_PAIR);
            $apiKey = $settings['ai_api_key'] ?? '';
            $model = $settings['ai_model'] ?? 'gemini-3.0-flash';

            if (empty($apiKey)) {
                return $this->json($response, ["error" => "AI API Key is not configured."], 500);
            }

            $lang = $_SESSION['lang'] ?? 'ar';
            $nativeLanguage = ($lang === 'en') ? 'English' : 'Arabic';
            
            // CRITICAL: Release the PHP session lock immediately before starting the long-running AI request 
            // so parallel apps/tabs don't freeze for several minutes waiting for the session file to unlock.
            session_write_close();

            $aiService = new \App\Services\AiGradingService($apiKey, $model);
            $evaluation = $aiService->gradeSingleEssay($essay, $essay['rubric'], $essay['grading_type'], $nativeLanguage);

            if (!$evaluation) {
                return $this->json($response, ["error" => "AI Service failed to evaluate the essay. Check API keys and limits."], 500);
            }

            $essayService = new EssayService(new EssayRepository($db));
            $essayService->gradeEssay(
                $resultId, 
                $evaluation['score_percentage'], 
                $evaluation['grade'], 
                $evaluation['feedback'], 
                $essay['student_id'],
                0 // earned_points fallback
            );

            return $this->json($response, [
                "status" => "success",
                "evaluation" => $evaluation
            ]);
        } catch (\Throwable $e) {
            $errorMsg = "Immediate AI Grading failed FATALLY: " . $e->getMessage() . " at " . $e->getFile() . ":" . $e->getLine();
            file_put_contents(__DIR__ . '/../../ai_debug.log', date('[Y-m-d H:i:s] ') . $errorMsg . "\n\n", FILE_APPEND);
            return $this->json($response, ["error" => $errorMsg], 500);
        }
    }
}
