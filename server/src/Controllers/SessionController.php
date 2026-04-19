<?php
namespace App\Controllers;

use App\Core\Database;
use App\Core\Validator;
use App\Repositories\SessionRepository;
use App\Services\SessionService;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;

class SessionController extends BaseController {
    public function startSession(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $studentId = $request->getAttribute('student_id');

        if (!$studentId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $validation = Validator::validate($data, ['exam_id' => 'required|numeric']);
        if (!$validation['passes']) return $this->json($response, ["error" => "Missing exam_id"], 400);

        $db = Database::getInstance();
        $sessionService = new SessionService(new SessionRepository($db));
        
        $ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
        try {
            $result = $sessionService->startSession($studentId, $validation['validated']['exam_id']);
            return $this->json($response, $result);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => $e->getMessage()], 400);
        }
    }

    public function heartbeat(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $studentId = $request->getAttribute('student_id');

        if (!$studentId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $validation = Validator::validate($data, [
            'exam_id' => 'required|numeric',
            'session_id' => 'required|string'
        ]);
        if (!$validation['passes']) return $this->json($response, ["error" => "Missing exam_id or session_id"], 400);

        $db = Database::getInstance();
        $sessionService = new SessionService(new SessionRepository($db));
        try {
            $sessionService->heartbeat($studentId, $validation['validated']['exam_id'], $validation['validated']['session_id']);
            return $this->json($response, ["status" => "success"]);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => $e->getMessage()], 400);
        }
    }

    public function listActive(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $db = Database::getInstance();
        $sessionService = new SessionService(new SessionRepository($db));
        
        return $this->json($response, $sessionService->listActiveSessions());
    }
}
