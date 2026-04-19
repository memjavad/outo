<?php
namespace App\Repositories;

use PDO;

class SecurityRepository {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    public function initRateLimitsTable() {
        $this->db->exec("CREATE TABLE IF NOT EXISTS rate_limits (
            id INT AUTO_INCREMENT PRIMARY KEY,
            ip_address VARCHAR(45) NOT NULL,
            endpoint VARCHAR(100) NOT NULL DEFAULT 'general',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_ip_time (ip_address, endpoint, created_at)
        )");
    }

    public function cleanRateLimits() {
        $this->db->exec("DELETE FROM rate_limits WHERE created_at < DATE_SUB(NOW(), INTERVAL 2 MINUTE)");
    }

    public function recordRateLimitHit(string $clientIp, string $endpoint) {
        $stmt = $this->db->prepare("INSERT INTO rate_limits (ip_address, endpoint) VALUES (?, ?)");
        $stmt->execute([$clientIp, $endpoint]);
    }

    public function getRateLimitHits(string $clientIp, string $endpoint): int {
        // Adjust timeframe natively, using hardcoded 60s
        $stmt = $this->db->prepare("SELECT COUNT(*) FROM rate_limits WHERE ip_address = ? AND endpoint = ? AND created_at > DATE_SUB(NOW(), INTERVAL 1 MINUTE)");
        $stmt->execute([$clientIp, $endpoint]);
        return (int)$stmt->fetchColumn();
    }

    public function getSetting(string $key): ?string {
        $stmt = $this->db->prepare("SELECT setting_value FROM settings WHERE setting_key = ?");
        $stmt->execute([$key]);
        $val = $stmt->fetchColumn();
        return $val === false ? null : (string)$val;
    }

    public function getAdminIdByToken(string $token): ?int {
        $stmt = $this->db->prepare("SELECT admin_id FROM admin_tokens WHERE token = ? AND expires_at > NOW()");
        $stmt->execute([$token]);
        $val = $stmt->fetchColumn();
        return $val === false ? null : (int)$val;
    }

    public function getStudentIdByToken(string $token): ?int {
        $stmt = $this->db->prepare("SELECT student_id FROM student_tokens WHERE token = ? AND expires_at > NOW()");
        $stmt->execute([$token]);
        $val = $stmt->fetchColumn();
        return $val === false ? null : (int)$val;
    }

    public function getFirstAdminId(): ?int {
        $val = $this->db->query("SELECT id FROM admins LIMIT 1")->fetchColumn();
        return $val === false ? null : (int)$val;
    }
}
