<?php
namespace App\Repositories;

use PDO;

class AdminRepository {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    public function findByUsername(string $username) {
        $stmt = $this->db->prepare("SELECT id, username, password_hash FROM admins WHERE username = ?");
        $stmt->execute([$username]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function countAdmins(): int {
        return (int)$this->db->query("SELECT COUNT(*) FROM admins")->fetchColumn();
    }

    public function createAdmin(string $username, string $passwordHash): int {
        $stmt = $this->db->prepare("INSERT INTO admins (username, password_hash) VALUES (?, ?)");
        $stmt->execute([$username, $passwordHash]);
        return (int)$this->db->lastInsertId();
    }

    public function createToken(int $adminId, string $token, string $expiresAt) {
        $stmt = $this->db->prepare("INSERT INTO admin_tokens (admin_id, token, expires_at) VALUES (?, ?, ?)");
        $stmt->execute([$adminId, $token, $expiresAt]);
    }

    public function findTelegramSession(string $sessionId) {
        $stmt = $this->db->prepare("SELECT * FROM tg_auth_sessions WHERE session_id = ?");
        $stmt->execute([$sessionId]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function createTelegramSession(string $sessionId) {
        $stmt = $this->db->prepare("INSERT IGNORE INTO tg_auth_sessions (session_id, status) VALUES (?, 'pending')");
        $stmt->execute([$sessionId]);
    }

    public function updateTelegramSession(string $sessionId, array $data) {
        $stmt = $this->db->prepare("UPDATE tg_auth_sessions SET status = 'authenticated', auth_date = ?, first_name = ?, username = ?, photo_url = ? WHERE session_id = ?");
        $stmt->execute([
            $data['auth_date'],
            $data['first_name'] ?? null,
            $data['username'] ?? null,
            $data['photo_url'] ?? null,
            $sessionId
        ]);
    }
}
