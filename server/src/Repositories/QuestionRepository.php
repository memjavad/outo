<?php
namespace App\Repositories;

use PDO;

class QuestionRepository {
    private PDO $db;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    public function getSummary() {
        return $this->db->query("SELECT * FROM questions")->fetchAll(PDO::FETCH_ASSOC) ?: [];
    }
    
    public function getSummaryByDomain(string $domain) {
        $stmt = $this->db->prepare("SELECT * FROM questions WHERE domain = ?");
        $stmt->execute([$domain]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    }

    public function getByExamId(int $examId, bool $randomize = false): array {
        $sql = "SELECT * FROM questions WHERE exam_id = ?";
        $sql .= $randomize ? " ORDER BY RAND()" : " ORDER BY created_at ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$examId]);
        $questions = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
        
        foreach ($questions as &$q) {
            $q['options'] = $this->getOptions($q['id']);
        }
        return $questions;
    }
    
    public function getAll(bool $randomize = false): array {
        $sql = "SELECT * FROM questions";
        $sql .= $randomize ? " ORDER BY RAND()" : " ORDER BY created_at ASC";
        $stmt = $this->db->query($sql);
        $questions = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
        
        foreach ($questions as &$q) {
            $q['options'] = $this->getOptions($q['id']);
        }
        return $questions;
    }

    public function getOptions(int $questionId): array {
        $stmt = $this->db->prepare("SELECT * FROM options WHERE question_id = ? ORDER BY option_index ASC");
        $stmt->execute([$questionId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
    }

    public function createQuestion(array $data): int {
        $fields = array_keys($data);
        $placeholders = implode(', ', array_fill(0, count($fields), '?'));
        $sql = "INSERT INTO questions (" . implode(', ', $fields) . ") VALUES ($placeholders)";
        $stmt = $this->db->prepare($sql);
        $stmt->execute(array_values($data));
        return (int)$this->db->lastInsertId();
    }

    public function createOption(int $questionId, string $text, int $index): bool {
        $stmt = $this->db->prepare("INSERT INTO options (question_id, option_text, option_index) VALUES (?, ?, ?)");
        return $stmt->execute([$questionId, $text, $index]);
    }
    
    /**
     * Bolt Optimization: Replaces N+1 single option inserts with a single chunked bulk insert query.
     * Expected Impact: Significantly reduces database round-trips when creating or updating questions
     * with multiple options. Performance scales O(1) in DB connections instead of O(N) where N is options count.
     */
    public function createOptionsBulk(array $optionsData): bool {
        if (empty($optionsData)) return true;

        $placeholders = [];
        $values = [];
        foreach ($optionsData as $option) {
            $placeholders[] = '(?, ?, ?)';
            $values[] = $option['question_id'];
            $values[] = $option['option_text'];
            $values[] = $option['option_index'];
        }

        $sql = "INSERT INTO options (question_id, option_text, option_index) VALUES " . implode(', ', $placeholders);
        $stmt = $this->db->prepare($sql);
        return $stmt->execute($values);
    }

    public function updateQuestion(int $id, array $data): bool {
        if (empty($data)) return true;
        $fields = [];
        $values = [];
        foreach ($data as $key => $value) {
            $fields[] = "$key = ?";
            $values[] = $value;
        }
        $values[] = $id;
        $sql = "UPDATE questions SET " . implode(', ', $fields) . " WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        return $stmt->execute($values);
    }
    
    public function deleteOptions(int $questionId): bool {
        $stmt = $this->db->prepare("DELETE FROM options WHERE question_id = ?");
        return $stmt->execute([$questionId]);
    }
}
