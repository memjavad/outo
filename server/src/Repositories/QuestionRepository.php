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

    private function attachOptions(array $questions): array {
        if (empty($questions)) {
            return [];
        }

        $questionIds = array_column($questions, 'id');
        $optionsByQuestionId = array_fill_keys($questionIds, []);

        // Chunking the IDs to avoid exceeding database limits on IN clause (SQLite limit is usually 999)
        $chunks = array_chunk($questionIds, 500);
        foreach ($chunks as $chunk) {
            $placeholders = implode(',', array_fill(0, count($chunk), '?'));
            $sql = "SELECT * FROM options WHERE question_id IN ($placeholders) ORDER BY question_id ASC, option_index ASC";
            $stmt = $this->db->prepare($sql);
            $stmt->execute($chunk);
            $options = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

            foreach ($options as $opt) {
                $optionsByQuestionId[$opt['question_id']][] = $opt;
            }
        }

        foreach ($questions as &$q) {
            $q['options'] = $optionsByQuestionId[$q['id']] ?? [];
        }

        return $questions;
    }

    public function getByExamId(int $examId, bool $randomize = false): array {
        $sql = "SELECT * FROM questions WHERE exam_id = ?";
        $sql .= $randomize ? " ORDER BY RAND()" : " ORDER BY created_at ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$examId]);
        $questions = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
        
        return $this->attachOptions($questions);
    }
    
    public function getAll(bool $randomize = false): array {
        $sql = "SELECT * FROM questions";
        $sql .= $randomize ? " ORDER BY RAND()" : " ORDER BY created_at ASC";
        $stmt = $this->db->query($sql);
        $questions = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
        
        return $this->attachOptions($questions);
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
