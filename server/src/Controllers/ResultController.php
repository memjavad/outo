<?php
namespace App\Controllers;

use App\Core\Database;
use App\Core\Validator;
use App\Repositories\ResultRepository;
use App\Services\ResultService;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;

class ResultController extends BaseController {
    public function saveResult(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $studentId = $request->getAttribute('student_id');

        if (!$studentId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $validation = Validator::validate($data, [
            'exam_id' => 'numeric',
            'examId' => 'numeric',
            'studentName' => 'string',
            'scorePercentage' => 'numeric',
            'correctAnswers' => 'numeric',
            'totalQuestions' => 'numeric',
            'timeTakenSeconds' => 'numeric',
            'gpsLocation' => 'string',
            'cheatFlag' => 'string',
            'answersJson' => 'array',
            'isGraded' => 'numeric',
            'studentId' => 'numeric',
            'earned_stars' => 'numeric',
            'campaign_score' => 'numeric'
        ]);

        // It is perfectly fine if it's less strict as long as it reaches ResultService

        if (!$validation['passes']) return $this->json($response, ["error" => "Missing required fields"], 400);

        $db = Database::getInstance();
        $resultService = new ResultService(new ResultRepository($db));

        try {
            $v = $validation['validated'];
            $v['studentId'] = (int)$studentId;
            $result = $resultService->saveResult($v);
            
            // Invalidate leaderboard cache instantly
            \App\Core\Cache::delete("leaderboard_exam_" . $v['exam_id']);
            \App\Core\Cache::delete("leaderboard_campaign_global");
            
            return $this->json($response, $result);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to save result: " . $e->getMessage()], 500);
        }
    }

    public function getStudentResults(Request $request, Response $response, array $args): Response {
        $studentId = $request->getAttribute('student_id');
        if (!$studentId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $db = Database::getInstance();
        $resultService = new ResultService(new ResultRepository($db));

        try {
            $results = $resultService->getStudentResults((int)$studentId);
            return $this->json($response, $results);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to fetch results: " . $e->getMessage()], 500);
        }
    }

    public function gradeResult(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $data = $request->getParsedBody() ?? [];
        $resultId = $data['id'] ?? null;
        if (!$resultId) return $this->json($response, ["error" => "Result ID missing"], 400);

        $validation = Validator::validate($data, [
            'score_percentage' => 'required|numeric',
            'grade' => 'required|string',
            'feedback' => 'string',
            'student_id' => 'required|numeric',
            'earned_points' => 'required|numeric'
        ]);

        if (!$validation['passes']) return $this->json($response, ["error" => "Validation failed", "details" => $validation['errors']], 400);

        $db = Database::getInstance();
        $resultService = new ResultService(new ResultRepository($db));

        try {
            $v = $validation['validated'];
            $result = $resultService->gradeResult((int)$resultId, (float)$v['score_percentage'], $v['grade'], $v['feedback'] ?? null, (int)$v['student_id'], (int)$v['earned_points']);
            
            // Invalidate any exam leaderboards associated visually
            \App\Core\Cache::delete("leaderboard_exam_*"); // Just a broad clear to be safe
            \App\Core\Cache::delete("leaderboard_campaign_global");
            
            return $this->json($response, $result);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to grade result: " . $e->getMessage()], 500);
        }
    }

    public function getPendingResults(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $db = Database::getInstance();
        try {
            $stmt = $db->query("
                SELECT r.*, e.title as exam_title 
                FROM results r 
                LEFT JOIN exams e ON r.exam_id = e.id 
                WHERE r.is_graded = 0 
                ORDER BY r.created_at DESC
            ");
            return $this->json($response, $stmt->fetchAll(\PDO::FETCH_ASSOC) ?: []);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to fetch pending results: " . $e->getMessage()], 500);
        }
    }

    public function getLeaderboard(Request $request, Response $response, array $args): Response {
        $data = $request->getQueryParams() ?? [];
        $validation = Validator::validate($data, ['exam_id' => 'required|numeric']);
        if (!$validation['passes']) return $this->json($response, ["error" => "exam_id is required"], 400);

        $db = Database::getInstance();
        $resultService = new ResultService(new ResultRepository($db));

        try {
            $examId = (int)$validation['validated']['exam_id'];
            $cacheKey = "leaderboard_exam_" . $examId;
            
            $leaderboard = \App\Core\Cache::remember($cacheKey, 60, function() use ($resultService, $examId) {
                return $resultService->getLeaderboard($examId);
            });
            
            return $this->json($response, $leaderboard);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to fetch leaderboard: " . $e->getMessage()], 500);
        }
    }

    public function getCampaignLeaderboard(Request $request, Response $response, array $args): Response {
        $db = Database::getInstance();
        $resultService = new ResultService(new ResultRepository($db));

        try {
            $cacheKey = "leaderboard_campaign_global";
            
            $leaderboard = \App\Core\Cache::remember($cacheKey, 300, function() use ($resultService) {
                return $resultService->getCampaignLeaderboard();
            });
            
            return $this->json($response, $leaderboard);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to fetch campaign leaderboard: " . $e->getMessage()], 500);
        }
    }

    public function clearResults(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $db = Database::getInstance();
        $resultService = new ResultService(new ResultRepository($db));

        try {
            $resultService->clearResults();
            return $this->json($response, ["status" => "success"]);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => $e->getMessage()], 500);
        }
    }
}
