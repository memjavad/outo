<?php
namespace App\Controllers;

use App\Core\Database;
use App\Core\Validator;
use App\Repositories\AdminRepository;
use App\Services\AuthService;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;

class AuthController extends BaseController {
    
    /**
     * API Login - Returns JSON with token
     */
    public function apiLogin(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $validation = Validator::validate($data, [
            'username' => 'required|string',
            'password' => 'required|string'
        ]);

        if (!$validation['passes']) return $this->json($response, ["error" => "Missing username or password"], 400);

        $db = Database::getInstance();
        $authService = new AuthService(new AdminRepository($db));
        
        $result = $authService->apiLogin($validation['validated']['username'], $validation['validated']['password']);
        
        if (isset($result['error'])) {
            return $this->json($response, $result, 401);
        }

        return $this->json($response, $result);
    }

    /**
     * Web Login - Sets session and redirects
     */
    public function webLogin($data) {
        $username = $data['username'] ?? '';
        $password = $data['password'] ?? '';
        
        if (empty($username) || empty($password)) {
            $_SESSION['login_error'] = "Missing username or password";
            return false;
        }

        $db = Database::getInstance();
        $authService = new AuthService(new AdminRepository($db));
        
        $result = $authService->authenticate($username, $password);
        if (isset($result['error'])) {
            $_SESSION['login_error'] = $result['error'];
            return false;
        }

        $_SESSION['admin_logged_in'] = true;
        $_SESSION['admin_id'] = $result['admin']['id'];
        $_SESSION['admin_user'] = $result['admin']['username'];

        // Force password change if using 'password'
        if ($result['is_default']) {
            $_SESSION['force_password_change'] = true;
        }

        return true;
    }

    /**
     * First-run Registration
     */
    public function registerFirstAdmin($data) {
        $username = $data['username'] ?? '';
        $password = $data['password'] ?? '';

        if (empty($username) || strlen($password) < 6) {
            $_SESSION['login_error'] = "Username required and Password must be 6+ chars.";
            return false;
        }

        $db = Database::getInstance();
        $authService = new AuthService(new AdminRepository($db));

        try {
            $authService->registerFirstAdmin($username, $password);
            return $this->webLogin($data);
        } catch (\Exception $e) {
            if ($e->getMessage() === "Admin already exists.") {
                die("Admin already exists.");
            }
            $_SESSION['login_error'] = $e->getMessage();
            return false;
        }
    }

    public function checkTelegramLogin(Request $request, Response $response, array $args): Response {
        $data = $request->getParsedBody() ?? [];
        $validation = Validator::validate($data, ['session_id' => 'required|string']);
        if (!$validation['passes']) return $this->json($response, ["error" => "Missing session_id"], 400);

        $db = Database::getInstance();
        $authService = new AuthService(new AdminRepository($db));

        try {
            $result = $authService->checkTelegramLogin($validation['validated']['session_id']);
            return $this->json($response, $result);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => $e->getMessage()], 404);
        }
    }
}
