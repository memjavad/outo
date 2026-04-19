<?php
namespace App\Repositories;

use PDO;
use PDOException;

class StoreRepository {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    public function getActiveItems(): array {
        $stmt = $this->db->query("SELECT * FROM store_items WHERE is_active = 1 ORDER BY cost_points ASC");
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    }

    public function getItemByKey(string $itemKey): ?array {
        $stmt = $this->db->prepare("SELECT * FROM store_items WHERE item_key = ?");
        $stmt->execute([$itemKey]);
        $item = $stmt->fetch(PDO::FETCH_ASSOC);
        return $item ?: null;
    }

    public function buyItem(int $studentId, string $itemKey, int $costPoints): bool {
        try {
            $this->db->beginTransaction();

            // Verify funds
            $stmt = $this->db->prepare("SELECT points FROM students WHERE id = ? FOR UPDATE");
            $stmt->execute([$studentId]);
            $student = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$student || (int)$student['points'] < $costPoints) {
                $this->db->rollBack();
                return false; // Insufficient funds
            }

            // Deduct Points
            $stmt = $this->db->prepare("UPDATE students SET points = points - ? WHERE id = ?");
            $stmt->execute([$costPoints, $studentId]);

            // Add to Inventory securely (Upsert)
            $stmt = $this->db->prepare("
                INSERT INTO student_inventory (student_id, item_key, quantity) 
                VALUES (?, ?, 1) 
                ON DUPLICATE KEY UPDATE quantity = quantity + 1
            ");
            $stmt->execute([$studentId, $itemKey]);

            // Inject ledger receipt optionally
            $stmt = $this->db->prepare("INSERT INTO points_ledger (student_name, amount, reason) SELECT name, ?, ? FROM students WHERE id = ?");
            $stmt->execute([-$costPoints, "Purchased Store Item: " . $itemKey, $studentId]);

            $this->db->commit();
            return true;
        } catch (PDOException $e) {
            $this->db->rollBack();
            return false;
        }
    }

    public function consumeItem(int $studentId, string $itemKey): bool {
        try {
            $this->db->beginTransaction();

            // Verify possession
            $stmt = $this->db->prepare("SELECT quantity FROM student_inventory WHERE student_id = ? AND item_key = ? FOR UPDATE");
            $stmt->execute([$studentId, $itemKey]);
            $inventory = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$inventory || (int)$inventory['quantity'] <= 0) {
                $this->db->rollBack();
                return false; // Does not have item
            }

            // Deduct quantity
            $stmt = $this->db->prepare("UPDATE student_inventory SET quantity = quantity - 1 WHERE student_id = ? AND item_key = ?");
            $stmt->execute([$studentId, $itemKey]);

            // Clean up 0 quantity rows to save space
            $this->db->exec("DELETE FROM student_inventory WHERE quantity <= 0");

            $this->db->commit();
            return true;
        } catch (PDOException $e) {
            $this->db->rollBack();
            return false;
        }
    }
}
