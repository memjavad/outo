<?php
namespace App\Services;

use App\Repositories\EssayRepository;

class EssayService {
    private EssayRepository $essayRepo;

    public function __construct(EssayRepository $essayRepo) {
        $this->essayRepo = $essayRepo;
    }

    public function saveEssayResult(array $data): array {
        $studentName = $data['student_name'] ?? $data['studentName'] ?? 'Unknown';
        
        $now = new \DateTime();
        $hour = (int)$now->format('H');
        $minHour = 9;
        $maxHour = 23;
        
        if ($hour >= $maxHour) {
            $scheduleDate = clone $now;
            $scheduleDate->modify('+1 day');
            $minTs = strtotime($scheduleDate->format('Y-m-d') . " 0$minHour:00:00");
            $maxTs = strtotime($scheduleDate->format('Y-m-d') . " $maxHour:00:00");
            $scheduledTimeStr = date('Y-m-d H:i:s', rand($minTs, $maxTs));
        } else {
            $startTimeInfo = max($now->getTimestamp(), strtotime($now->format('Y-m-d') . " 0$minHour:00:00"));
            $endTimeInfo = strtotime($now->format('Y-m-d') . " $maxHour:00:00");
            $scheduledTimeStr = date('Y-m-d H:i:s', rand($startTimeInfo, $endTimeInfo));
        }

        $resultData = [
            'student_name' => $studentName,
            'student_id' => $data['student_id'] ?? null,
            'exam_id' => $data['exam_id'] ?? $data['examId'] ?? null,
            'score_percentage' => 0,
            'grade' => 'Pending Grading',
            'time_taken_seconds' => $data['time_taken_seconds'] ?? $data['timeTakenSeconds'] ?? 0,
            'gps_location' => $data['gps_location'] ?? $data['gpsLocation'] ?? null,
            'cheat_flag' => $data['cheat_flag'] ?? $data['cheatFlag'] ?? null,
            'answers_json' => isset($data['answers_json']) ? json_encode($data['answers_json']) : (isset($data['answersJson']) ? json_encode($data['answersJson']) : null),
            'is_graded' => 0,
            'scheduled_grading_time' => $scheduledTimeStr
        ];

        $resultId = $this->essayRepo->createEssayResult($resultData);
        
        $this->triggerWebhook('essay_submitted', $data);
        
        return [
            "status" => "success", 
            "id" => $resultId, 
            "points_earned" => 0
        ];
    }

    public function gradeEssay(int $resultId, float $scorePct, string $grade, ?string $feedback, int $studentIdTarget, int $earnedPoints): array {
        $this->essayRepo->gradeEssay($resultId, $scorePct, $grade, $feedback);
        
        return [
            "status" => "success",
            "message" => "Essay graded successfully."
        ];
    }

    public function getPendingEssays(): array {
        return $this->essayRepo->getPendingEssays();
    }

    private function triggerWebhook(string $eventName, array $payload) {
        if ($this->essayRepo->isWebhookEnabled()) {
            $webhooks = $this->essayRepo->getActiveWebhooks($eventName);
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
