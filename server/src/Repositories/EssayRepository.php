<?php
namespace App\Repositories;

use PDO;

class EssayRepository {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    public function createEssayResult(array $data): int {
        $stmt = $this->db->prepare("INSERT INTO essay_results (student_name, student_id, exam_id, score_percentage, grade, time_taken_seconds, gps_location, cheat_flag, answers_json, is_graded, scheduled_grading_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['student_name'],
            $data['student_id'],
            $data['exam_id'],
            $data['score_percentage'],
            $data['grade'],
            $data['time_taken_seconds'],
            $data['gps_location'],
            $data['cheat_flag'],
            $data['answers_json'],
            $data['is_graded'] ?? 0,
            $data['scheduled_grading_time'] ?? null
        ]);
        return (int)$this->db->lastInsertId();
    }

    public function gradeEssay(int $resultId, float $scorePercentage, string $grade, ?string $feedback): void {
        $stmt = $this->db->prepare("UPDATE essay_results SET score_percentage = ?, grade = ?, teacher_feedback = ?, is_graded = 1 WHERE id = ?");
        $stmt->execute([$scorePercentage, $grade, $feedback, $resultId]);
    }

    public function getPendingEssays(): array {
        $stmt = $this->db->prepare("
            SELECT r.*, e.title as exam_title, e.exam_type 
            FROM essay_results r 
            LEFT JOIN exams e ON r.exam_id = e.id 
            WHERE r.is_graded = 0 
            ORDER BY r.created_at DESC
        ");
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
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
