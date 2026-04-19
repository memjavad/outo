<?php
require_once __DIR__ . '/db_connect.php';

spl_autoload_register(function ($class) {
    if (strpos($class, 'App\\') === 0) {
        $file = __DIR__ . '/src/' . str_replace('\\', '/', substr($class, 4)) . '.php';
        if (file_exists($file)) {
            require_once $file;
        }
    }
});

use App\Core\Database;
use App\Repositories\AdminRepository;
use App\Services\AuthService;

$sessionId = $_GET['session_id'] ?? '';

if (empty($sessionId)) {
    die("Error: Session ID is missing.");
}

$db = Database::getInstance();
$stmt = $db->query("SELECT setting_value FROM settings WHERE setting_key = 'tg_bot_token'");
$botToken = $stmt->fetchColumn();

if (empty($botToken)) {
    die("Error: Telegram Bot Token is not configured.");
}

try {
    $authService = new AuthService(new AdminRepository($db));
    $authService->verifyTelegramCallback($_GET, $botToken, $sessionId);
    
    echo "<!DOCTYPE html><html><head><title>Success</title><meta name='viewport' content='width=device-width, initial-scale=1.0'><style>body { font-family: -apple-system, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f3f4f6; margin:0;} .card { background: white; padding: 40px; border-radius: 16px; text-align: center; box-shadow: 0 10px 25px rgba(0,0,0,0.05); max-width: 400px; width: 90%; } h2 { color: #10b981; font-weight: 700; margin-top: 16px; } p { color: #6b7280; line-height: 1.5; }</style></head><body><div class='card'><svg style='width: 64px; height: 64px; color: #10b981;' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'></path></svg><h2>Authentication Successful!</h2><p>Your Telegram identity has been securely verified. You may now close this browser window and return to the exam app.</p><script>setTimeout(function(){ window.close(); }, 3000);</script></div></body></html>";
    
} catch (Exception $e) {
    echo "<!DOCTYPE html><html><head><title>Failed</title><meta name='viewport' content='width=device-width, initial-scale=1.0'><style>body { font-family: -apple-system, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f3f4f6; margin:0;} .card { background: white; padding: 40px; border-radius: 16px; text-align: center; box-shadow: 0 10px 25px rgba(0,0,0,0.05); max-width: 400px; width: 90%; } h2 { color: #ef4444; font-weight: 700; margin-top: 16px; } p { color: #6b7280; line-height: 1.5; }</style></head><body><div class='card'><svg style='width: 64px; height: 64px; color: #ef4444;' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z'></path></svg><h2>Authentication Failed</h2><p>" . htmlspecialchars($e->getMessage()) . "</p></div></body></html>";
}
?>
