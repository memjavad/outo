<?php
namespace App\Controllers;

use App\Core\Database;
use App\Repositories\ExamRepository;
use App\Repositories\QuestionRepository;
use App\Services\ExamService;
use App\Services\AuditService;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;

class ExamController extends BaseController {
    
    public function getQuestions(Request $request, Response $response, array $args): Response {
        $db = Database::getInstance();
        $stmtSettings = $db->query("SELECT setting_value FROM settings WHERE setting_key = 'randomize_questions'");
        $randSetting = $stmtSettings->fetchColumn();
        $isRand = ($randSetting === false || $randSetting == '1');
        
        $data = $request->getQueryParams() ?? [];
        $examId = $data['exam_id'] ?? null;
        
        $questionRepo = new QuestionRepository($db);
        
        if ($examId) {
            $questions = $questionRepo->getByExamId((int)$examId, $isRand);
        } else {
            $questions = $questionRepo->getAll($isRand);
        }

        $result = [];
        foreach ($questions as $q) {
            $optionsList = array_map(fn($opt) => $opt['option_text'], $q['options']);

            $result[] = [
                'id' => (string)$q['id'],
                'categoryId' => $q['category_id'] ? (string)$q['category_id'] : null,
                'examId' => $q['exam_id'] ? (string)$q['exam_id'] : null,
                'question' => $q['question_text'],
                'richText' => $q['rich_text'],
                'imageUrl' => $q['image_url'],
                'questionType' => $q['question_type'] ?? 'single',
                'options' => $optionsList,
                'correctAnswerIndex' => (int)$q['correct_answer_index'],
                'points' => (int)($q['points'] ?? 1)
            ];
        }
        return $this->json($response, $result);
    }

    public function getExams(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        $db = Database::getInstance();
        $examRepo = new ExamRepository($db);

        if ($adminId) {
            $stmtRole = $db->prepare("SELECT role FROM admins WHERE id = ?");
            $stmtRole->execute([$adminId]);
            $role = $stmtRole->fetchColumn();
            
            if ($role === 'admin') {
                return $this->json($response, $examRepo->getAllForAdmin());
            } else {
                return $this->json($response, $examRepo->getAllForTeacher($adminId));
            }
        } else {
            return $this->json($response, $examRepo->getAllActive());
        }
    }

    public function addQuestion(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $files = $request->getUploadedFiles() ?? [];
        $db = Database::getInstance();
        $questionRepo = new QuestionRepository($db);

        $validation = \App\Core\Validator::validate($data, [
            'question_text' => 'required|string'
        ]);
        if (!$validation['passes']) return $this->json($response, ["error" => "Validation failed", "details" => $validation['errors']], 400);
        $questionText = $validation['validated']['question_text'];

        $categoryId = !empty($data['category_id']) ? $data['category_id'] : null;
        $examId = !empty($data['exam_id']) ? $data['exam_id'] : null;
        $questionText = $data['question_text'] ?? '';
        $richText = !empty($data['rich_text']) ? $data['rich_text'] : null;
        $correctIndex = $data['correct_index'] ?? 0;
        $domain = $data['domain'] ?? 'standard';
        
        $options = [];
        for ($i = 0; $i < 4; $i++) {
            if (isset($data["option_$i"])) $options[] = $data["option_$i"];
        }

        try {
            $db->beginTransaction();
            $imageUrl = null;
            $uploadedFile = current($request->getUploadedFiles()); // Try to grab if single
            if (isset($files['question_image'])) $uploadedFile = $files['question_image'];
            
            if ($uploadedFile && $uploadedFile->getError() === UPLOAD_ERR_OK) {
                $upload = $this->uploadImage($uploadedFile);
                $imageUrl = $upload['url'] ?? null;
            }

            $questionData = [
                'category_id' => $categoryId,
                'exam_id' => $examId,
                'question_text' => $questionText,
                'rich_text' => $richText,
                'image_url' => $imageUrl,
                'correct_answer_index' => $correctIndex,
                'domain' => $domain,
                'question_type' => $data['question_type'] ?? 'multiple_choice'
            ];

            $questionId = $questionRepo->createQuestion($questionData);

            foreach ($options as $index => $text) {
                $questionRepo->createOption($questionId, $text, $index);
            }

            $db->commit();
            return $this->json($response, ["status" => "success", "id" => $questionId, "question" => $questionText, "imageUrl" => $imageUrl]);
        } catch (\Exception $e) {
            if ($db->inTransaction()) $db->rollBack();
            return $this->json($response, ["error" => $e->getMessage()], 500);
        }
    }

    public function addExam(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $db = Database::getInstance();
        $examRepo = new ExamRepository($db);

        $validation = \App\Core\Validator::validate($data, [
            'title' => 'required|string',
            'description' => 'string',
            'exam_type' => 'string',
            'grading_type' => 'string',
            'rubric' => 'string'
        ]);
        if (!$validation['passes']) {
            return $this->json($response, ["error" => "Validation failed", "details" => $validation['errors']], 400);
        }
        $validation['validated']['grading_type'] = $data['grading_type'] ?? 'percentage';
        $validation['validated']['rubric'] = $data['rubric'] ?? null;
        
        $examService = new ExamService($examRepo);

        try {
            $result = $examService->addExam($validation['validated'], $adminId);
            if (isset($result['id'])) {
                $audit = new AuditService($db);
                $audit->logAction((int)$adminId, "create_exam", ["exam_id" => $result['id'], "title" => $validation['validated']['title']]);
            }
            return $this->json($response, $result);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => $e->getMessage()], 500);
        }
    }

    public function bulkImport(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $files = $request->getUploadedFiles() ?? [];
        if (empty($files['excel_file'])) {
            return $this->json($response, ["error" => "No file uploaded"], 400);
        }

        $file = $files['excel_file'];
        if ($file->getError() !== UPLOAD_ERR_OK) {
            return $this->json($response, ["error" => "File upload error"], 400);
        }

        $extension = strtolower(pathinfo($file->getClientFilename(), PATHINFO_EXTENSION));
        if ($extension !== 'xlsx') {
            return $this->json($response, ["error" => "Invalid format. Only .xlsx allowed."], 400);
        }

        if (!is_dir(__DIR__ . '/../../uploads')) mkdir(__DIR__ . '/../../uploads', 0777, true);
        $destPath = __DIR__ . '/../../uploads/temp_' . bin2hex(random_bytes(8)) . '.xlsx';
        $file->moveTo($destPath);

        if (class_exists(\Shuchkin\SimpleXLSX::class)) {
            $xlsx = \Shuchkin\SimpleXLSX::parse($destPath);
            if (!$xlsx) {
                unlink($destPath);
                return $this->json($response, ["error" => \Shuchkin\SimpleXLSX::parseError()], 400);
            }
            $rows = $xlsx->rows();
            unlink($destPath);
        } else {
            return $this->json($response, ["error" => "SimpleXLSX library not installed"], 500);
        }

        if (count($rows) <= 1) {
            return $this->json($response, ["error" => "Excel file is empty or missing data."], 400);
        }

        array_shift($rows); // Remove header
        
        $db = Database::getInstance();
        $examService = new ExamService(new ExamRepository($db));
        
        try {
            $result = $examService->bulkImportQuestions($rows, new QuestionRepository($db));
            $audit = new AuditService($db);
            $audit->logAction((int)$adminId, "bulk_import_questions", ["count" => $result['count']]);
            return $this->json($response, $result);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => $e->getMessage()], 500);
        }
    }

    public function downloadTemplate(Request $request, Response $response, array $args): Response {
        $data = [
            ['Category ID (Optional)', 'Exam ID (Optional)', 'Question (Required)', 'Option 1', 'Option 2', 'Option 3', 'Option 4', 'Correct Index 1-4', 'Type (standard)'],
            ['', '', 'Who developed the theory of relativity?', 'Isaac Newton', 'Albert Einstein', 'Niels Bohr', 'Galileo Galilei', '2', 'standard'],
            ['', '', 'What is the powerhouse of the cell?', 'Nucleus', 'Mitochondria', 'Ribosome', 'Endoplasmic reticulum', '2', 'standard']
        ];
        
        $xlsx = \Shuchkin\SimpleXLSXGen::fromArray($data);
        $tmp = tempnam(sys_get_temp_dir(), 'xlsx');
        $xlsx->saveAs($tmp);
        $content = file_get_contents($tmp);
        unlink($tmp);

        $response->getBody()->write($content);
        return $response
            ->withHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
            ->withHeader('Content-Disposition', 'attachment; filename="template.xlsx"')
            ->withHeader('Cache-Control', 'max-age=0');
    }

    public function updateExam(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $db = Database::getInstance();
        $examRepo = new ExamRepository($db);

        $validation = \App\Core\Validator::validate($data, [
            'id' => 'required|numeric',
            'title' => 'required|string',
            'description' => 'string',
            'exam_type' => 'string',
            'rubric' => 'string'
        ]);
        if (!$validation['passes']) {
            return $this->json($response, ["error" => "Validation failed", "details" => $validation['errors']], 400);
        }
        $validation['validated']['rubric'] = $data['rubric'] ?? null;
        $id = $validation['validated']['id'];

        $examService = new ExamService($examRepo);

        try {
            $result = $examService->updateExam((int)$id, $data);
            $adminId = $request->getAttribute('admin_id');
            if ($adminId) {
                $audit = new AuditService($db);
                $audit->logAction((int)$adminId, "update_exam", ["exam_id" => $id]);
            }
            return $this->json($response, $result);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => $e->getMessage()], 500);
        }
    }

    public function getQuestionDetails(Request $request, Response $response, array $args): Response {
        $data = $request->getQueryParams() ?? [];
        $db = Database::getInstance();
        $validation = \App\Core\Validator::validate($data, ['id' => 'required|numeric']);
        if (!$validation['passes']) return $this->json($response, ["error" => "ID is required"], 400);
        $id = $validation['validated']['id'];

        $stmt = $db->prepare("SELECT * FROM questions WHERE id = ?");
        $stmt->execute([$id]);
        $q = $stmt->fetch(\PDO::FETCH_ASSOC);
        if (!$q) return $this->json($response, ["error" => "Question not found"], 404);

        $questionRepo = new QuestionRepository($db);
        $q['options'] = $questionRepo->getOptions($id);

        return $this->json($response, $q);
    }

    public function updateQuestion(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $files = $request->getUploadedFiles() ?? [];
        $db = Database::getInstance();
        $questionRepo = new QuestionRepository($db);

        $validation = \App\Core\Validator::validate($data, [
            'id' => 'required|numeric',
            'question_text' => 'required|string'
        ]);
        if (!$validation['passes']) return $this->json($response, ["error" => "Validation failed", "details" => $validation['errors']], 400);
        
        $id = $validation['validated']['id'];
        $questionText = $validation['validated']['question_text'];

        $options = [];
        for ($i = 0; $i < 4; $i++) {
            if (isset($data["option_$i"])) $options[] = $data["option_$i"];
        }

        try {
            $db->beginTransaction();
            
            // Handle image update
            $imageUrl = $data['existing_image'] ?? null;
            $uploadedFile = current($request->getUploadedFiles());
            if (isset($files['question_image'])) $uploadedFile = $files['question_image'];
            
            if ($uploadedFile && $uploadedFile->getError() === UPLOAD_ERR_OK) {
                $upload = $this->uploadImage($uploadedFile);
                $imageUrl = $upload['url'] ?? null;
            }

            $questionData = [
                'category_id' => !empty($data['category_id']) ? $data['category_id'] : null,
                'exam_id' => !empty($data['exam_id']) ? $data['exam_id'] : null,
                'question_text' => $questionText,
                'rich_text' => !empty($data['rich_text']) ? $data['rich_text'] : null,
                'image_url' => $imageUrl,
                'correct_answer_index' => $data['correct_index'] ?? 0,
                'domain' => $data['domain'] ?? 'standard'
            ];

            $questionRepo->updateQuestion((int)$id, $questionData);

            $questionRepo->deleteOptions((int)$id);
            foreach ($options as $index => $text) {
                $questionRepo->createOption((int)$id, $text, $index);
            }

            $db->commit();
            return $this->json($response, ["status" => "success", "message" => "Question updated", "imageUrl" => $imageUrl]);
        } catch (\Exception $e) {
            if ($db->inTransaction()) $db->rollBack();
            return $this->json($response, ["error" => $e->getMessage()], 500);
        }
    }

    public function uploadImage($file) {
        if ($file->getError() !== UPLOAD_ERR_OK) {
            return ["error" => "File upload failed"];
        }

        $extension = pathinfo($file->getClientFilename(), PATHINFO_EXTENSION);
        $newName = bin2hex(random_bytes(16)) . '.' . $extension;
        $destPath = __DIR__ . '/../../uploads/' . $newName;

        if (!is_dir(__DIR__ . '/../../uploads')) {
            mkdir(__DIR__ . '/../../uploads', 0777, true);
        }

        $file->moveTo($destPath);
        return [
            "url" => "/uploads/" . $newName,
            "filename" => $newName
        ];
    }

    public function checkAccessCode(Request $request, Response $response, array $args): Response {
        $data = $request->getQueryParams() ?? [];
        $validation = \App\Core\Validator::validate($data, ['access_code' => 'required|string']);
        if (!$validation['passes']) return $this->json($response, ["error" => "Access code required"], 400);

        $db = Database::getInstance();
        $stmt = $db->prepare("SELECT id FROM exams WHERE access_code = ? AND active = 1");
        $stmt->execute([$validation['validated']['access_code']]);
        $examId = $stmt->fetchColumn();

        if ($examId) {
            return $this->json($response, ["status" => "success", "exam_id" => $examId]);
        } else {
            return $this->json($response, ["error" => "Invalid or inactive exam access code"], 404);
        }
    }
}
