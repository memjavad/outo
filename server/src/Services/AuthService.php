<?php
namespace App\Services;

use App\Repositories\AdminRepository;

class AuthService {
    private AdminRepository $adminRepo;

    public function __construct(AdminRepository $adminRepo) {
        $this->adminRepo = $adminRepo;
    }

    public function authenticate(string $username, string $password) {
        $admin = $this->adminRepo->findByUsername($username);

        if ($admin && password_verify($password, $admin['password_hash'])) {
            return [
                "admin" => ["id" => $admin['id'], "username" => $admin['username']],
                "is_default" => password_verify('password', $admin['password_hash'])
            ];
        }

        return ["error" => "Invalid username or password"];
    }

    public function apiLogin(string $username, string $password) {
        $result = $this->authenticate($username, $password);
        if (isset($result['error'])) {
            return $result;
        }

        $token = bin2hex(random_bytes(32));
        $expiresAt = date('Y-m-d H:i:s', strtotime('+24 hours'));
        
        $this->adminRepo->createToken($result['admin']['id'], $token, $expiresAt);
        
        return [
            "status" => "success",
            "admin" => $result['admin'],
            "token" => $token
        ];
    }

    public function registerFirstAdmin(string $username, string $password) {
        if ($this->adminRepo->countAdmins() > 0) {
            throw new \Exception("Admin already exists.");
        }

        if (strlen($password) < 6) {
            throw new \Exception("Password must be 6+ chars.");
        }

        $hash = password_hash($password, PASSWORD_DEFAULT);
        $this->adminRepo->createAdmin($username, $hash);

        return $this->authenticate($username, $password);
    }

    public function checkTelegramLogin(string $sessionId) {
        $session = $this->adminRepo->findTelegramSession($sessionId);
        if ($session) {
            return ["status" => "success", "data" => $session];
        }
        throw new \Exception("Session not found", 404);
    }

    public function initTelegramSession(string $sessionId) {
        $this->adminRepo->createTelegramSession($sessionId);
    }

    public function verifyTelegramCallback(array $authData, string $botToken, string $sessionId): array {
        if (!isset($authData['hash'])) {
            throw new \Exception('Hash is missing from Telegram payload');
        }
        
        $checkHash = $authData['hash'];
        unset($authData['hash']);
        unset($authData['session_id']);
        
        $dataCheckArr = [];
        foreach ($authData as $key => $value) {
            $dataCheckArr[] = $key . '=' . $value;
        }
        sort($dataCheckArr);
        $dataCheckString = implode("\n", $dataCheckArr);
        
        $secretKey = hash('sha256', $botToken, true);
        $hash = hash_hmac('sha256', $dataCheckString, $secretKey);
        
        if (strcmp($hash, $checkHash) !== 0) {
            throw new \Exception('Data is NOT from Telegram (Hash verification failed)');
        }
        if ((time() - $authData['auth_date']) > 86400) {
            throw new \Exception('Data is outdated');
        }
        
        $this->adminRepo->updateTelegramSession($sessionId, $authData);
        
        return $authData;
    }
}
