<?php
namespace App\Controllers;

use App\Core\Database;
use App\Repositories\StudentRepository;
use App\Services\StudentService;
use App\Services\AuditService;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;

class StudentController extends BaseController {
    
    public function getStudents(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);
        $db = Database::getInstance();
        $studentRepo = new StudentRepository($db);
        return $this->json($response, $studentRepo->getAll());
    }

    public function addStudent(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $validation = \App\Core\Validator::validate($data, [
            'name' => 'required|string',
            'phone' => 'required|string',
            'password' => 'required|string'
        ]);

        if (!$validation['passes']) {
            return $this->json($response, ["error" => "Validation failed", "details" => $validation['errors']], 400);
        }
        $val = $validation['validated'];

        $db = Database::getInstance();
        $studentService = new StudentService(new StudentRepository($db));
        
        try {
            return $this->json($response, $studentService->addStudent($val));
        } catch (\Exception $e) {
            $code = $e->getCode() ?: 500;
            if ($code === 0) $code = 400; // default for known domain errors
            return $this->json($response, ["error" => $e->getMessage()], $code);
        }
    }

    public function bulkImport(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);
        
        $data = $request->getParsedBody() ?? [];
        if (!isset($data['students']) || !is_array($data['students'])) {
            return $this->json($response, ["error" => "Missing students array"], 400);
        }

        $db = Database::getInstance();
        $studentService = new StudentService(new StudentRepository($db));
        $result = $studentService->bulkImport($data['students']);
        
        if (isset($result['count']) && $result['count'] > 0) {
            $audit = new AuditService($db);
            $audit->logAction((int)$adminId, "bulk_import", ["count" => $result['count']]);
        }
        
        return $this->json($response, $result);
    }

    public function registerStudent(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $validation = \App\Core\Validator::validate($data, [
            'name' => 'required|string',
            'phone' => 'required|string',
            'password' => 'required|string'
        ]);

        if (!$validation['passes']) {
            return $this->json($response, ["error" => "Validation failed", "details" => $validation['errors']], 400);
        }
        $val = $validation['validated'];

        $db = Database::getInstance();
        $studentService = new StudentService(new StudentRepository($db));
        
        try {
            return $this->json($response, $studentService->registerStudent($val));
        } catch (\Exception $e) {
            return $this->json($response, ["status" => "error", "error" => "Registration failed: " . $e->getMessage()], 200);
        }
    }

    public function loginStudent(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $validation = \App\Core\Validator::validate($data, [
            'phone' => 'required|string',
            'password' => 'required|string'
        ]);

        if (!$validation['passes']) {
            return $this->json($response, ["error" => "Validation failed", "details" => $validation['errors']], 400);
        }
        $val = $validation['validated'];

        $db = Database::getInstance();
        $studentService = new StudentService(new StudentRepository($db));
        
        try {
            return $this->json($response, $studentService->loginStudent($val));
        } catch (\Exception $e) {
            return $this->json($response, ["status" => "error", "error" => $e->getMessage()], 200);
        }
    }

    public function getProfile(Request $request, Response $response, array $args): Response {
        $studentId = $request->getAttribute('student_id');
        if (!$studentId) return $this->json($response, ["error" => "Unauthorized"], 401);
        
        $db = Database::getInstance();
        $studentRepo = new StudentRepository($db);
        $student = $studentRepo->findById($studentId);

        if ($student) {
            unset($student['password_hash']);
            return $this->json($response, $student);
        }
        return $this->json($response, ["error" => "Student not found"], 404);
    }

    public function updateProfile(Request $request, Response $response, array $args): Response {
        $studentId = $request->getAttribute('student_id');
        $data = $request->getParsedBody() ?? [];
        $files = $request->getUploadedFiles() ?? [];
        
        if (!$studentId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $db = Database::getInstance();
        $studentRepo = new StudentRepository($db);
        
        $name = $data['name'] ?? null;
        $bio = $data['bio'] ?? null;
        
        $updateData = [];

        if ($name) $updateData['name'] = $name;
        if ($bio !== null) $updateData['bio'] = $bio;

        if (isset($files['profile_image']) && $files['profile_image']->getError() === UPLOAD_ERR_OK) {
            $examController = new ExamController();
            $upload = $examController->uploadImage($files['profile_image']);
            if (isset($upload['url'])) {
                $updateData['profile_image'] = $upload['url'];
            }
        }

        if (empty($updateData)) return $this->json($response, ["status" => "success", "message" => "No changes made"]);

        try {
            $studentRepo->update($studentId, $updateData);
            return $this->json($response, ["status" => "success", "message" => "Profile updated"]);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Profile update failed"], 500);
        }
    }

    public function getPendingStudents(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);
        $db = Database::getInstance();
        $studentRepo = new StudentRepository($db);
        return $this->json($response, $studentRepo->getPending());
    }

    public function approveStudent(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        $data = $request->getParsedBody() ?? [];
        
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);
        $validation = \App\Core\Validator::validate($data, ['id' => 'required|numeric']);
        if (!$validation['passes']) return $this->json($response, ["error" => "Student ID required"], 400);

        $id = $validation['validated']['id'];

        $db = Database::getInstance();
        $studentRepo = new StudentRepository($db);
        try {
            $studentRepo->approve($id);
            $audit = new AuditService($db);
            $audit->logAction((int)$adminId, "approve_student", ["student_id" => $id]);
            return $this->json($response, ["status" => "success", "message" => "Student approved"]);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to approve student"], 500);
        }
    }

    public function rejectStudent(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        $data = $request->getParsedBody() ?? [];
        
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);
        $validation = \App\Core\Validator::validate($data, ['id' => 'required|numeric']);
        if (!$validation['passes']) return $this->json($response, ["error" => "Student ID required"], 400);

        $id = $validation['validated']['id'];

        $db = Database::getInstance();
        $studentRepo = new StudentRepository($db);
        try {
            $studentRepo->reject($id);
            $audit = new AuditService($db);
            $audit->logAction((int)$adminId, "reject_student", ["student_id" => $id]);
            return $this->json($response, ["status" => "success", "message" => "Student rejected"]);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to reject student"], 500);
        }
    }
}
