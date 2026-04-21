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
        
        return $this->attachOptionsToQuestions($questions);
    }
    
    public function getAll(bool $randomize = false): array {
        $sql = "SELECT * FROM questions";
        $sql .= $randomize ? " ORDER BY RAND()" : " ORDER BY created_at ASC";
        $stmt = $this->db->query($sql);
        $questions = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
        
        return $this->attachOptionsToQuestions($questions);
    }


    private function attachOptionsToQuestions(array $questions): array {
        if (empty($questions)) {
            return [];
        }

        $questionIds = array_column($questions, 'id');
        $placeholders = implode(',', array_fill(0, count($questionIds), '?'));

        $stmt = $this->db->prepare("SELECT * FROM options WHERE question_id IN ($placeholders) ORDER BY question_id ASC, option_index ASC");
        $stmt->execute($questionIds);
        $allOptions = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

        $optionsByQuestionId = [];
        foreach ($allOptions as $option) {
            $optionsByQuestionId[$option['question_id']][] = $option;
        }

        foreach ($questions as &$q) {
            $q['options'] = $optionsByQuestionId[$q['id']] ?? [];
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
