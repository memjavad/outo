<?php
namespace App\Repositories;

use PDO;

class ResultRepository {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    public function createResult(array $data): int {
        $stmt = $this->db->prepare("INSERT INTO results (student_name, student_id, exam_id, score_percentage, grade, total_questions, correct_answers, time_taken_seconds, gps_location, cheat_flag, answers_json, is_graded, earned_stars, campaign_score) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['student_name'],
            $data['student_id'],
            $data['exam_id'],
            $data['score_percentage'],
            $data['grade'],
            $data['total_questions'],
            $data['correct_answers'],
            $data['time_taken_seconds'],
            $data['gps_location'],
            $data['cheat_flag'],
            $data['answers_json'],
            $data['is_graded'] ?? 1,
            $data['earned_stars'] ?? 0,
            $data['campaign_score'] ?? 0
        ]);
        $resultId = (int)$this->db->lastInsertId();

        // Natively unpack and log Distractor Data Analytics securely into atomic relations
        if (!empty($data['answers_json'])) {
            $parsed = json_decode($data['answers_json'], true);
            if (is_array($parsed)) {
                $respStmt = $this->db->prepare("INSERT INTO student_responses (result_id, exam_id, question_id, selected_option_index) VALUES (?, ?, ?, ?)");
                foreach ($parsed as $qId => $selectedOption) {
                    if (is_numeric($qId) && is_numeric($selectedOption)) {
                        $respStmt->execute([
                            $resultId,
                            $data['exam_id'],
                            (int)$qId,
                            (int)$selectedOption
                        ]);
                    }
                }
            }
        }

        return $resultId;
    }

    public function gradeResult(int $resultId, float $scorePercentage, string $grade, ?string $feedback): void {
        $stmt = $this->db->prepare("UPDATE results SET score_percentage = ?, grade = ?, teacher_feedback = ?, is_graded = 1 WHERE id = ?");
        $stmt->execute([$scorePercentage, $grade, $feedback, $resultId]);
    }

    public function getDb(): PDO {
        return $this->db;
    }

    public function markSessionCompleted(string $studentName) {
        $stmt = $this->db->prepare("UPDATE active_sessions SET status = 'completed' WHERE student_name = ? AND status = 'active'");
        $stmt->execute([$studentName]);
    }

    public function awardPoints(int $studentId, int $points) {
        $stmt = $this->db->prepare("UPDATE students SET points = COALESCE(points, 0) + ?, total_xp = COALESCE(total_xp, 0) + ? WHERE id = ?");
        $stmt->execute([$points, $points, $studentId]);
    }
    
    public function awardStars(int $studentId, int $stars) {
        if ($stars <= 0) return;
        $stmt = $this->db->prepare("UPDATE students SET stars = COALESCE(stars, 0) + ? WHERE id = ?");
        $stmt->execute([$stars, $studentId]);
    }

    public function insertLedger(string $studentName, int $points, string $reason) {
        $stmt = $this->db->prepare("INSERT INTO points_ledger (student_name, amount, reason) VALUES (?, ?, ?)");
        $stmt->execute([$studentName, $points, $reason]);
    }

    public function getStudentResults(int $studentId): array {
        $stmt = $this->db->prepare("
            SELECT r.id, r.exam_id, r.score_percentage, r.grade, r.time_taken_seconds, r.cheat_flag, r.created_at, r.is_graded, r.teacher_feedback, e.title as exam_title, e.exam_type, r.total_questions, r.correct_answers, r.earned_stars, r.campaign_score
            FROM results r 
            LEFT JOIN exams e ON r.exam_id = e.id 
            WHERE r.student_id = ? 
            UNION ALL
            SELECT er.id, er.exam_id, er.score_percentage, er.grade, er.time_taken_seconds, er.cheat_flag, er.created_at, er.is_graded, er.teacher_feedback, e.title as exam_title, e.exam_type, 1 as total_questions, 1 as correct_answers, 0 as earned_stars, 0 as campaign_score 
            FROM essay_results er
            LEFT JOIN exams e ON er.exam_id = e.id 
            WHERE er.student_id = ? 
            ORDER BY created_at DESC
        ");
        $stmt->execute([$studentId, $studentId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getLeaderboard(int $examId): array {
        $stmt = $this->db->prepare("
            SELECT student_name, MAX(score_percentage) as score_percentage, MIN(time_taken_seconds) as time_taken_seconds 
            FROM (
                SELECT student_name, score_percentage, time_taken_seconds, exam_id FROM results 
                UNION ALL 
                SELECT student_name, score_percentage, time_taken_seconds, exam_id FROM essay_results
            ) as combined_results
            WHERE exam_id = ? 
            GROUP BY student_name 
            ORDER BY score_percentage DESC, time_taken_seconds ASC 
            LIMIT 50
        ");
        $stmt->execute([$examId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getCampaignLeaderboard(): array {
        $stmt = $this->db->query("
            SELECT name as student_name, COALESCE(total_xp, 0) as score_percentage, 0 as time_taken_seconds
            FROM students
            WHERE total_xp > 0
            ORDER BY total_xp DESC
            LIMIT 50
        ");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function clearResults() {
        $this->db->exec("DELETE FROM results");
        $this->db->exec("DELETE FROM essay_results");
    }

    public function isWebhookEnabled(): bool {
        $stmt = $this->db->query("SELECT setting_value FROM settings WHERE setting_key = 'webhook_enabled'");
        return $stmt->fetchColumn() === '1';
    }

    public function getActiveWebhooks(string $eventName): array {
        $stmt = $this->db->prepare("SELECT url FROM webhooks WHERE event_name = ? AND is_active = 1");
        $stmt->execute([$eventName]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
