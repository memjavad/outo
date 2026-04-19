<?php
namespace App\Services;

use App\Core\Database;
use PDO;
use Exception;

class AuditService {
    private $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    /**
     * securely log an administrative action
     * 
     * @param int|null $adminId The ID of the admin performing the action
     * @param string $action The action identifier (e.g. 'delete_exam', 'update_student')
     * @param string|array $details Detailed context (converted to JSON if array)
     */
    public function logAction(?int $adminId, string $action, $details = null) {
        $ip = $_SERVER['REMOTE_ADDR'] ?? null;
        
        if (is_array($details)) {
            $details = json_encode($details);
        }

        try {
            $stmt = $this->db->prepare("INSERT INTO audit_log (admin_id, action, details, ip_address) VALUES (?, ?, ?, ?)");
            $stmt->execute([$adminId, $action, $details, $ip]);
            return true;
        } catch (Exception $e) {
            error_log("AuditService failed to record action: " . $action . " | " . $e->getMessage());
            return false;
        }
    }
}
