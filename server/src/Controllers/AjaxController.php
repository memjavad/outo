<?php
namespace App\Controllers;

use App\Core\Database;
use App\Core\Validator;
use App\Services\AuditService;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;

class AjaxController extends BaseController {
    public function getAnalytics(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $db = Database::getInstance();
        
        $totalStudents = $db->query("SELECT COUNT(*) FROM students")->fetchColumn();
        $totalExams = $db->query("SELECT COUNT(*) FROM exams")->fetchColumn();
        $totalQuestions = $db->query("SELECT COUNT(*) FROM questions")->fetchColumn();
        $totalResults = $db->query("SELECT COUNT(*) FROM results")->fetchColumn();
        
        try {
            $stmt = $db->query("
                SELECT 
                    CASE 
                        WHEN score_percentage >= 90 THEN 'A'
                        WHEN score_percentage >= 80 THEN 'B'
                        WHEN score_percentage >= 70 THEN 'C'
                        WHEN score_percentage >= 60 THEN 'D'
                        ELSE 'F' 
                    END as grade,
                    COUNT(*) as count
                FROM results 
                GROUP BY grade
            ");
            $distribution = $stmt->fetchAll();
        } catch (\Exception $e) {
            $distribution = [];
        }

        // Assuming the user intended to replace the original return structure with a new one,
        // and the provided snippet was a partial/malformed representation of that new structure.
        // I'm interpreting the intent to return a simplified set of stats.
        // If 'recent_results' is needed, its fetching logic would need to be added.
        return $this->json($response, [
            "total_students" => $totalStudents, // Using existing $totalStudents
            "total_questions" => $totalQuestions, // Using existing $totalQuestions
            "total_exams" => $totalExams, // Using existing $totalExams
            // "recent_results" => $results // This variable ($results) is not defined in the original or new context.
                                          // Keeping it commented out as per strict instruction adherence.
                                          // If it was meant to be $totalResults, it should be explicitly stated.
            "grade_distribution" => $distribution // Adding the distribution back as it was fetched.
        ]);
    }

    public function deleteItem(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $data = $request->getParsedBody() ?? [];
        $validation = Validator::validate($data, [
            'type' => 'required|string',
            'id' => 'required|numeric'
        ]);

        if (!$validation['passes']) return $this->json($response, ["error" => "Resource not found or invalid format"], 400);

        $db = Database::getInstance();
        $table = "";
        switch($validation['validated']['type']) {
            case 'student': $table = "students"; break;
            case 'question': $table = "questions"; break;
            case 'exam': $table = "exams"; break;
            case 'category': $table = "categories"; break;
            default: return $this->json($response, ["error" => "Invalid type"], 400);
        }

        try {
            $stmt = $db->prepare("DELETE FROM $table WHERE id = ?");
            $stmt->execute([$validation['validated']['id']]);
            
            $audit = new AuditService($db);
            $audit->logAction((int)$adminId, "delete_item", [
                "type" => $table,
                "id" => $validation['validated']['id']
            ]);

            return $this->json($response, ["status" => "success", "message" => "Item deleted"]);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => "Failed to delete: " . $e->getMessage()], 500);
        }
    }
}
