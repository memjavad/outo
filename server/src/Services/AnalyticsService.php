<?php
namespace App\Services;

use App\Core\Database;

class AnalyticsService {
    private \PDO $db;

    public function __construct() {
        $this->db = Database::getInstance();
    }

    public function getExamKPIs(int $examId): array {
        // Calculate Platform KPIs for a specific exam
        $stmt = $this->db->prepare("
            SELECT 
                COUNT(*) as total_taken,
                AVG(score_percentage) as average_score,
                AVG(time_taken_seconds) as average_time_seconds,
                SUM(CASE WHEN score_percentage >= 50 THEN 1 ELSE 0 END) as passed_count
            FROM results
            WHERE exam_id = ?
        ");
        $stmt->execute([$examId]);
        $data = $stmt->fetch(\PDO::FETCH_ASSOC);

        $total = (int)($data['total_taken'] ?? 0);
        $passCount = (int)($data['passed_count'] ?? 0);
        
        return [
            'total_students' => $total,
            'average_score' => round((float)($data['average_score'] ?? 0), 2),
            'average_time_seconds' => round((float)($data['average_time_seconds'] ?? 0), 0),
            'pass_rate' => $total > 0 ? round(($passCount / $total) * 100, 2) : 0
        ];
    }

    public function getDistractorAnalysis(int $examId): array {
        // Fetch Distractor Metrics: For each question, what % chose Option 0, 1, 2, 3?
        $stmt = $this->db->prepare("
            SELECT 
                q.id as question_id,
                q.question_text,
                sr.selected_option_index,
                COUNT(sr.id) as pick_count
            FROM questions q
            JOIN student_responses sr ON q.id = sr.question_id
            WHERE q.exam_id = ? AND q.question_type != 'essay'
            GROUP BY q.id, sr.selected_option_index
            ORDER BY q.id
        ");
        $stmt->execute([$examId]);
        $rows = $stmt->fetchAll(\PDO::FETCH_ASSOC);

        // Group rows natively by question
        $questions = [];
        foreach ($rows as $row) {
            $qId = $row['question_id'];
            if (!isset($questions[$qId])) {
                $questions[$qId] = [
                    'question_id' => $qId,
                    'question_text' => $row['question_text'],
                    'total_answers' => 0,
                    'options_distribution' => []
                ];
            }
            
            $optIdx = $row['selected_option_index'] !== null ? (int)$row['selected_option_index'] : -1;
            $count = (int)$row['pick_count'];
            
            $questions[$qId]['options_distribution'][$optIdx] = $count;
            $questions[$qId]['total_answers'] += $count;
        }

        // Convert counts to percentages
        $finalData = [];
        foreach ($questions as $q) {
            $dist = [];
            foreach ($q['options_distribution'] as $optIdx => $count) {
                // Return structure: [{optionIndex: 0, percentage: 45.5}, ...]
                $dist[] = [
                    'option_index' => $optIdx,
                    'percentage' => round(($count / $q['total_answers']) * 100, 2)
                ];
            }
            $finalData[] = [
                'question_id' => $q['question_id'],
                'question_text' => $q['question_text'],
                'total_answers' => $q['total_answers'],
                'distractors' => $dist
            ];
        }

        return $finalData;
    }
}
