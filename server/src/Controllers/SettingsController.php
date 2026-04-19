<?php
namespace App\Controllers;

use App\Core\Database;
use PDO;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;

class SettingsController extends BaseController {
    public function getSettings(Request $request, Response $response, array $args): Response {
        $db = Database::getInstance();
        $settingsRepo = new \App\Repositories\SettingsRepository($db);
        $settings = $settingsRepo->getAll();
        
        // Security: Remove sensitive keys from public API
        unset($settings['tg_bot_token']);
        unset($settings['api_key']);
        
        return $this->json($response, $settings);
    }

    public function updateSettings(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $data = $request->getParsedBody() ?? [];
        $db = Database::getInstance();
        $settingsRepo = new \App\Repositories\SettingsRepository($db);
        
        try {
            $settingsRepo->updateMany($data, ['api_key', 'action']);
            return $this->json($response, ["status" => "success"]);
        } catch (\Exception $e) {
            return $this->json($response, ["error" => $e->getMessage()], 500);
        }
    }

    public function getSystemLogs(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $logFiles = [
            __DIR__ . '/../../php_errors.log',
            __DIR__ . '/../../ai_debug.log'
        ];
        
        $output = "=== System & AI Processing Logs ===\n\n";
        $hasLogs = false;
        
        foreach ($logFiles as $file) {
            if (file_exists($file) && filesize($file) > 0) {
                $hasLogs = true;
                $output .= "--- [" . basename($file) . "] ---\n";
                $content = file_get_contents($file, false, null, 0, 500000); 
                $output .= htmlspecialchars($content) . "\n\n";
            }
        }
        
        if (!$hasLogs) {
             $output .= "No recent logs found. The system is operating normally.";
        }

        return $this->json($response, ["status" => "success", "logs" => $output]);
    }

    public function clearSystemLogs(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $logFiles = [
            __DIR__ . '/../../php_errors.log',
            __DIR__ . '/../../ai_debug.log'
        ];
        
        foreach ($logFiles as $file) {
            if (file_exists($file)) {
                file_put_contents($file, "");
            }
        }

        return $this->json($response, ["status" => "success"]);
    }

    public function testAiConnection(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        $data = $request->getParsedBody() ?? [];
        $apiKey = $data['ai_api_key'] ?? '';
        $model = $data['ai_model'] ?? 'gemini-3.0-flash';

        if (empty($apiKey)) {
            return $this->json($response, ["error" => "API Key is required"], 400);
        }

        $url = "https://generativelanguage.googleapis.com/v1beta/models/" . urlencode($model) . ":generateContent?key=" . urlencode($apiKey);
        
        $payload = [
            'contents' => [
                ['parts' => [['text' => 'reply with OK']]]
            ]
        ];

        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
        curl_setopt($ch, CURLOPT_TIMEOUT, 5);

        $result = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if ($httpCode !== 200) {
            $errorData = json_decode($result, true);
            $errorMsg = $errorData['error']['message'] ?? 'Invalid API Key or Model';
            return $this->json($response, ["error" => $errorMsg], 400);
        }

        return $this->json($response, ["status" => "success"]);
    }

    public function fixDatabaseSchema(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);
        $db = Database::getInstance();
        $migrator = new \App\Core\Migrator($db);
        $result = $migrator->up();
        
        if (isset($result['error']) || (isset($result['status']) && $result['status'] === 'error')) {
            return $this->json($response, $result, 500);
        }
        
        return $this->json($response, $result);
    }
}
