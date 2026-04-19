<?php
namespace App\Repositories;

use PDO;

class SessionRepository {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    public function createSession(string $studentName, int $examId, int $totalQuestions, string $ipAddress) {
        $stmt = $this->db->prepare("INSERT INTO active_sessions (student_name, exam_id, total_questions, ip_address) VALUES (?, ?, ?, ?)");
        $stmt->execute([$studentName, $examId, $totalQuestions, $ipAddress]);
    }

    public function updateHeartbeat(string $studentName, int $currentQuestion, int $answeredCount) {
        $stmt = $this->db->prepare("UPDATE active_sessions SET current_question = ?, answered_count = ?, last_heartbeat = NOW() WHERE student_name = ? AND status = 'active'");
        $stmt->execute([$currentQuestion, $answeredCount, $studentName]);
    }

    public function cleanStaleSessions() {
        $this->db->exec("UPDATE active_sessions SET status = 'abandoned' WHERE status = 'active' AND last_heartbeat < DATE_SUB(NOW(), INTERVAL 5 MINUTE)");
    }

    public function getActiveSessions(): array {
        $stmt = $this->db->query("SELECT * FROM active_sessions WHERE status = 'active' ORDER BY last_heartbeat DESC");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
