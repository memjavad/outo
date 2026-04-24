<?php
namespace App\Services;

use App\Repositories\ExamRepository;

class ExamService {
    private ExamRepository $examRepo;

    public function __construct(ExamRepository $examRepo) {
        $this->examRepo = $examRepo;
    }

    public function addExam(array $validatedData, $adminId): array {
        $examData = [
            'title' => $validatedData['title'] ?? '',
            'description' => $validatedData['description'] ?? '',
            'created_by' => $adminId,
            'exam_timer' => (int)($validatedData['exam_timer'] ?? 10),
            'question_timer' => (int)($validatedData['question_timer'] ?? 0),
            'randomize_questions' => isset($validatedData['randomize_questions']) ? (int)$validatedData['randomize_questions'] : 1,
            'randomize_options' => isset($validatedData['randomize_options']) ? (int)$validatedData['randomize_options'] : 1,
            'strict_app_focus' => isset($validatedData['strict_app_focus']) ? (int)$validatedData['strict_app_focus'] : 0,
            'detect_vpn' => isset($validatedData['detect_vpn']) ? (int)$validatedData['detect_vpn'] : 0,
            'require_gps' => isset($validatedData['require_gps']) ? (int)$validatedData['require_gps'] : 0,
            'record_screen' => isset($validatedData['record_screen']) ? (int)$validatedData['record_screen'] : 0,
            'require_biometrics' => isset($validatedData['require_biometrics']) ? (int)$validatedData['require_biometrics'] : 0,
            'require_tg_login' => isset($validatedData['require_tg_login']) ? (int)$validatedData['require_tg_login'] : 0,
            'require_access_code' => isset($validatedData['require_access_code']) ? (int)$validatedData['require_access_code'] : 0,
            'record_audio' => isset($validatedData['record_audio']) ? (int)$validatedData['record_audio'] : 0,
            'immediate_feedback' => isset($validatedData['immediate_feedback']) ? (int)$validatedData['immediate_feedback'] : 0,
            'prevent_screenshots' => isset($validatedData['prevent_screenshots']) ? (int)$validatedData['prevent_screenshots'] : 1,
            'allow_review' => isset($validatedData['allow_review']) ? (int)$validatedData['allow_review'] : 1,
            'allow_backtracking' => isset($validatedData['allow_backtracking']) ? (int)$validatedData['allow_backtracking'] : 1,
            'exam_start_date' => !empty($validatedData['exam_start_date']) ? $validatedData['exam_start_date'] : null,
            'exam_end_date' => !empty($validatedData['exam_end_date']) ? $validatedData['exam_end_date'] : null,
            'exam_type' => $validatedData['exam_type'] ?? 'standard',
            'grading_type' => $validatedData['grading_type'] ?? 'percentage',
            'rubric' => $validatedData['rubric'] ?? null,
            'prerequisite_exam_id' => !empty($validatedData['prerequisite_exam_id']) ? $validatedData['prerequisite_exam_id'] : null,
            'unlock_cost' => isset($validatedData['unlock_cost']) ? (int)$validatedData['unlock_cost'] : 0
        ];

        $examId = $this->examRepo->create($examData);
        
        return [
            "status" => "success",
            "id" => $examId,
            "title" => $examData['title'],
            "exam_type" => $examData['exam_type']
        ];
    }

    public function updateExam(int $id, array $validatedData): array {
        $examData = [
            'title' => $validatedData['title'] ?? '',
            'description' => $validatedData['description'] ?? '',
            'exam_timer' => (int)($validatedData['exam_timer'] ?? 10),
            'question_timer' => (int)($validatedData['question_timer'] ?? 0),
            'randomize_questions' => isset($validatedData['randomize_questions']) ? (int)$validatedData['randomize_questions'] : 1,
            'randomize_options' => isset($validatedData['randomize_options']) ? (int)$validatedData['randomize_options'] : 1,
            'strict_app_focus' => isset($validatedData['strict_app_focus']) ? (int)$validatedData['strict_app_focus'] : 0,
            'detect_vpn' => isset($validatedData['detect_vpn']) ? (int)$validatedData['detect_vpn'] : 0,
            'require_gps' => isset($validatedData['require_gps']) ? (int)$validatedData['require_gps'] : 0,
            'record_screen' => isset($validatedData['record_screen']) ? (int)$validatedData['record_screen'] : 0,
            'require_biometrics' => isset($validatedData['require_biometrics']) ? (int)$validatedData['require_biometrics'] : 0,
            'require_tg_login' => isset($validatedData['require_tg_login']) ? (int)$validatedData['require_tg_login'] : 0,
            'require_access_code' => isset($validatedData['require_access_code']) ? (int)$validatedData['require_access_code'] : 0,
            'record_audio' => isset($validatedData['record_audio']) ? (int)$validatedData['record_audio'] : 0,
            'immediate_feedback' => isset($validatedData['immediate_feedback']) ? (int)$validatedData['immediate_feedback'] : 0,
            'prevent_screenshots' => isset($validatedData['prevent_screenshots']) ? (int)$validatedData['prevent_screenshots'] : 1,
            'allow_review' => isset($validatedData['allow_review']) ? (int)$validatedData['allow_review'] : 1,
            'allow_backtracking' => isset($validatedData['allow_backtracking']) ? (int)$validatedData['allow_backtracking'] : 1,
            'exam_start_date' => !empty($validatedData['exam_start_date']) ? $validatedData['exam_start_date'] : null,
            'exam_end_date' => !empty($validatedData['exam_end_date']) ? $validatedData['exam_end_date'] : null,
            'exam_type' => $validatedData['exam_type'] ?? 'standard',
            'grading_type' => $validatedData['grading_type'] ?? 'percentage',
            'rubric' => $validatedData['rubric'] ?? null,
            'prerequisite_exam_id' => !empty($validatedData['prerequisite_exam_id']) ? $validatedData['prerequisite_exam_id'] : null,
            'unlock_cost' => isset($validatedData['unlock_cost']) ? (int)$validatedData['unlock_cost'] : 0
        ];

        $this->examRepo->update($id, $examData);
        
        return ["status" => "success", "message" => "Exam updated"];
    }

    public function bulkImportQuestions(array $rows, \App\Repositories\QuestionRepository $questionRepo): array {
        $count = 0;
        foreach ($rows as $row) {
            $categoryId = !empty($row[0]) ? (int)$row[0] : null;
            $examId = !empty($row[1]) ? (int)$row[1] : null;
            $questionText = trim($row[2] ?? '');
            
            if (empty($questionText)) continue;

            $opts = [
                trim($row[3] ?? ''),
                trim($row[4] ?? ''),
                trim($row[5] ?? ''),
                trim($row[6] ?? '')
            ];
            
            $correctIndexRaw = (int)($row[7] ?? 1);
            $correctIndex = max(0, $correctIndexRaw - 1); 
            $domain = trim($row[8] ?? 'standard');

            $questionData = [
                'category_id' => $categoryId,
                'exam_id' => $examId,
                'question_text' => $questionText,
                'correct_answer_index' => $correctIndex,
                'domain' => $domain
            ];

            $qId = $questionRepo->createQuestion($questionData);
            
            $optionsData = [];
            foreach ($opts as $idx => $optText) {
                if (!empty($optText)) {
                    $optionsData[] = ['question_id' => $qId, 'option_text' => $optText, 'option_index' => $idx];
                }
            }
            if (!empty($optionsData)) {
                $questionRepo->createOptionsBulk($optionsData);
            }
            $count++;
        }

        return ["status" => "success", "count" => $count, "message" => "$count questions imported successfully."];
    }
}
