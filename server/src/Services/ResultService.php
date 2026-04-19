<?php
namespace App\Services;

use App\Repositories\ResultRepository;

class ResultService {
    private ResultRepository $resultRepo;

    public function __construct(ResultRepository $resultRepo) {
        $this->resultRepo = $resultRepo;
    }

    public function saveResult(array $data): array {
        $studentName = $data['studentName'];
        
        // Manual Essay Override Interception
        $isGraded = 1;
        $scorePercentage = $data['scorePercentage'] ?? 0;
        $grade = $data['grade'] ?? 'F';
        $earnedPoints = 0; // Calculated later if graded

        $examId = $data['examId'] ?? null;
        if ($examId) {
            $examRepo = new \App\Repositories\ExamRepository($this->resultRepo->getDb());
            $examData = $examRepo->getById((int)$examId);
            if ($examData && $examData['exam_type'] === 'essay') {
                $isGraded = 0;
                $scorePercentage = 0;
                $grade = 'Pending Grading';
            }
        }
        
        $resultData = [
            'student_name' => $studentName,
            'student_id' => $data['studentId'] ?? null,
            'exam_id' => $examId,
            'score_percentage' => $scorePercentage,
            'grade' => $grade,
            'total_questions' => $data['totalQuestions'] ?? 0,
            'correct_answers' => $data['correctAnswers'] ?? 0,
            'time_taken_seconds' => $data['timeTakenSeconds'] ?? 0,
            'gps_location' => $data['gpsLocation'] ?? null,
            'cheat_flag' => $data['cheatFlag'] ?? null,
            'answers_json' => isset($data['answersJson']) ? json_encode($data['answersJson']) : null,
            'is_graded' => $isGraded,
            'earned_stars' => $data['earned_stars'] ?? 0,
            'campaign_score' => $data['campaign_score'] ?? 0
        ];

        $resultId = $this->resultRepo->createResult($resultData);
        $this->resultRepo->markSessionCompleted($studentName);
        
        if (isset($data['studentId']) && isset($data['earned_stars']) && (int)$data['earned_stars'] > 0) {
            $this->resultRepo->awardStars((int)$data['studentId'], (int)$data['earned_stars']);
        }
        
        // Calculate and Award Reward Points
        $earnedPoints = 0;
        if (isset($data['studentId']) && isset($data['campaign_score']) && (int)$data['campaign_score'] > 0) {
            $this->resultRepo->awardPoints((int)$data['studentId'], (int)$data['campaign_score']);
            $earnedPoints = (int)$data['campaign_score'];
        } else if ($isGraded === 1 && isset($data['studentId'])) {
            $correctAns = (int)($data['correctAnswers'] ?? 0);
            $totalQ = (int)($data['totalQuestions'] ?? 0);
            $timeTaken = (int)($data['timeTakenSeconds'] ?? 99999);
            $scoreStr = rtrim((string)($data['scorePercentage'] ?? '0'), '% ');
            $scorePct = (float)$scoreStr;
            
            $earnedPoints = $correctAns * 10;
            if ($scorePct >= 99.9) $earnedPoints += 50; // Flawless DB mapping
            if ($timeTaken > 0 && $timeTaken <= ($totalQ * 30)) $earnedPoints += 25; // Speed bonus mapping
            $earnedPoints = max(10, $earnedPoints); // Min participation award
            
            $this->resultRepo->awardPoints((int)$data['studentId'], $earnedPoints);
        }

        $this->triggerWebhook('result_submitted', $data);
        
        return [
            "status" => "success", 
            "id" => $resultId, 
            "points_earned" => $earnedPoints
        ];
    }

    public function getStudentResults(int $studentId): array {
        return $this->resultRepo->getStudentResults($studentId);
    }

    public function gradeResult(int $resultId, float $scorePct, string $grade, ?string $feedback, int $studentIdTarget, int $earnedPoints): array {
        $this->resultRepo->gradeResult($resultId, $scorePct, $grade, $feedback);
        
        return [
            "status" => "success",
            "message" => "Result graded safely."
        ];
    }

    public function getLeaderboard(int $examId): array {
        $leaderboard = $this->resultRepo->getLeaderboard($examId);
        return [
            "status" => "success",
            "leaderboard" => $leaderboard
        ];
    }

    public function getCampaignLeaderboard(): array {
        $leaderboard = $this->resultRepo->getCampaignLeaderboard();
        return [
            "status" => "success",
            "leaderboard" => $leaderboard
        ];
    }

    public function clearResults(): array {
        $this->resultRepo->clearResults();
        return ["status" => "success"];
    }

    private function triggerWebhook(string $eventName, array $payload) {
        if ($this->resultRepo->isWebhookEnabled()) {
            $webhooks = $this->resultRepo->getActiveWebhooks($eventName);
            foreach ($webhooks as $row) {
                $ch = curl_init($row['url']);
                curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
                curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_TIMEOUT, 2);
                curl_exec($ch);
            }
        }
    }
}
