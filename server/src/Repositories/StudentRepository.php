<?php
namespace App\Repositories;

use PDO;

class StudentRepository {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    public function getAllEnrolled(): array {
        $stmt = $this->db->query("SELECT id, name, phone, email, access_code FROM students WHERE enrolled = 1 ORDER BY name ASC");
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    }

    public function getAll(): array {
        $stmt = $this->db->query("SELECT * FROM students ORDER BY name ASC");
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    }

    public function getPending(): array {
        $stmt = $this->db->query("SELECT id, name, phone, created_at FROM students WHERE enrolled = 0 ORDER BY created_at DESC");
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    }

    public function findById(int $id): ?array {
        $stmt = $this->db->prepare("SELECT * FROM students WHERE id = ?");
        $stmt->execute([$id]);
        $student = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($student) {
            $invStmt = $this->db->prepare("SELECT item_key, quantity FROM student_inventory WHERE student_id = ? AND quantity > 0");
            $invStmt->execute([$id]);
            $inventory = [];
            foreach ($invStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
                $inventory[$row['item_key']] = (int)$row['quantity'];
            }
            $student['inventory'] = $inventory;
        }
        
        return $student ?: null;
    }

    public function findByPhone(string $phone): ?array {
        $stmt = $this->db->prepare("SELECT * FROM students WHERE phone = ?");
        $stmt->execute([$phone]);
        $student = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($student) {
            $invStmt = $this->db->prepare("SELECT item_key, quantity FROM student_inventory WHERE student_id = ? AND quantity > 0");
            $invStmt->execute([$student['id']]);
            $inventory = [];
            foreach ($invStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
                $inventory[$row['item_key']] = (int)$row['quantity'];
            }
            $student['inventory'] = $inventory;
        }
        
        return $student ?: null;
    }

    public function approve(int $id): bool {
        $stmt = $this->db->prepare("UPDATE students SET enrolled = 1 WHERE id = ?");
        return $stmt->execute([$id]);
    }

    public function reject(int $id): bool {
        $stmt = $this->db->prepare("DELETE FROM students WHERE id = ? AND enrolled = 0");
        return $stmt->execute([$id]);
    }

    public function create(array $data): int {
        $stmt = $this->db->prepare("INSERT INTO students (name, phone, password_hash, enrolled) VALUES (?, ?, ?, ?)");
        $stmt->execute([
            $data['name'],
            $data['phone'],
            $data['password_hash'],
            $data['enrolled'] ?? 1
        ]);
        return (int)$this->db->lastInsertId();
    }

    public function update(int $id, array $data): bool {
        if (empty($data)) return true;
        $fields = [];
        $values = [];
        foreach ($data as $key => $value) {
            $fields[] = "$key = ?";
            $values[] = $value;
        }
        $values[] = $id;
        $sql = "UPDATE students SET " . implode(', ', $fields) . " WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        return $stmt->execute($values);
    }

    public function createToken(int $studentId, string $token, string $expires): bool {
        $stmt = $this->db->prepare("INSERT INTO student_tokens (student_id, token, expires_at) VALUES (?, ?, ?)");
        return $stmt->execute([$studentId, $token, $expires]);
    }

    public function importStudent(string $name, ?string $accessCode): bool {
        $stmt = $this->db->prepare("INSERT INTO students (name, access_code) VALUES (?, ?)");
        return $stmt->execute([$name, $accessCode]);
    }
}
