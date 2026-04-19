<?php
namespace App\Services;

use App\Repositories\SecurityRepository;

class SecurityService {
    private SecurityRepository $securityRepo;

    public function __construct(SecurityRepository $securityRepo) {
        $this->securityRepo = $securityRepo;
    }

    public function enforceRateLimits(string $clientIp, string $endpoint = 'general', int $maxRequestsPerMinute = 200) {
        $this->securityRepo->initRateLimitsTable();
        $this->securityRepo->cleanRateLimits();
        
        $hits = $this->securityRepo->getRateLimitHits($clientIp, $endpoint);
        if ($hits >= $maxRequestsPerMinute) {
            throw new \Exception("Too many requests. Please try again later.", 429);
        }

        $this->securityRepo->recordRateLimitHit($clientIp, $endpoint);
    }

    public function enforceIpWhitelist(string $clientIp) {
        $whitelistStr = $this->securityRepo->getSetting('ip_whitelist');
        
        if ($whitelistStr && !empty(trim($whitelistStr))) {
            $whitelistItems = array_map('trim', explode(',', $whitelistStr));
            if (!in_array($clientIp, $whitelistItems)) {
                throw new \Exception("Access denied. IP not whitelisted.", 403);
            }
        }
    }

    public function resolveAuthentication(string $authHeader, ?string $apiKeyHeader, array $sessionData): array {
        $isAdmin = false;
        $adminId = null;
        $studentId = null;

        // 1. Bearer Token Check
        if (strpos($authHeader, 'Bearer ') === 0) {
            $token = substr($authHeader, 7);
            
            $dbAdminId = $this->securityRepo->getAdminIdByToken($token);
            if ($dbAdminId !== null) {
                $isAdmin = true;
                $adminId = $dbAdminId;
            } else {
                $dbStudentId = $this->securityRepo->getStudentIdByToken($token);
                if ($dbStudentId !== null) {
                    $studentId = $dbStudentId;
                }
            }
        }

        // 2. API Key Fallback
        if (!$isAdmin && $apiKeyHeader) {
            $storedKey = $this->securityRepo->getSetting('api_key');
            if ($storedKey && !empty($storedKey) && $apiKeyHeader === $storedKey) {
                $isAdmin = true;
                $adminId = $this->securityRepo->getFirstAdminId();
            }
        }

        // 3. Web Dashboard PHP Session Fallback (from index.php wrapper)
        if (!$isAdmin && isset($sessionData['admin_logged_in']) && $sessionData['admin_logged_in'] === true) {
            $isAdmin = true;
            $adminId = $sessionData['admin_id'] ?? null;
        }

        return [
            'is_admin' => $isAdmin,
            'admin_id' => $adminId,
            'student_id' => $studentId
        ];
    }
}
