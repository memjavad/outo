<?php
namespace App\Core;

class Auth {
    public static function generateToken($adminId) {
        $secret = Config::get('jwt_secret');
        $payload = json_encode([
            'admin_id' => $adminId,
            'exp' => time() + Config::get('token_expiry')
        ]);
        $base64Payload = base64_encode($payload);
        $signature = hash_hmac('sha256', $base64Payload, $secret);
        $token = $base64Payload . '.' . $signature;
        
        // Store in DB for logout/revocation support
        $db = Database::getInstance();
        $stmt = $db->prepare("INSERT INTO admin_tokens (admin_id, token, expires_at) VALUES (?, ?, FROM_UNIXTIME(?))");
        $stmt->execute([$adminId, $token, time() + Config::get('token_expiry')]);
        
        return $token;
    }

    public static function verifyToken($token) {
        if (!$token) return false;
        $parts = explode('.', $token);
        if (count($parts) !== 2) return false;
        
        [$base64Payload, $signature] = $parts;
        $secret = Config::get('jwt_secret');
        $expectedSignature = hash_hmac('sha256', $base64Payload, $secret);
        
        if (!hash_equals($expectedSignature, $signature)) return false;
        
        $payload = json_decode(base64_decode($base64Payload), true);
        if (!$payload || ($payload['exp'] ?? 0) < time()) return false;
        
        return $payload['admin_id'];
    }

    public static function checkRole($adminId, $requiredRole) {
        $db = Database::getInstance();
        $stmt = $db->prepare("SELECT role FROM admins WHERE id = ?");
        $stmt->execute([$adminId]);
        $role = $stmt->fetchColumn();
        
        $roles = ['viewer' => 1, 'teacher' => 2, 'admin' => 3];
        return ($roles[$role] ?? 0) >= ($roles[$requiredRole] ?? 0);
    }
}
