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
$stmt = $db->query("SELECT setting_value FROM settings WHERE setting_key = 'tg_bot_username'");
$botUsername = $stmt->fetchColumn();

if (empty($botUsername)) {
    die("Error: Telegram Bot is not configured by the administrator.");
}

// ── Initialize Session in DB ──
// This is critical so that the callback can UPDATE it and polling can find it.
$authService = new AuthService(new AdminRepository($db));
$authService->initTelegramSession($sessionId);

// Construct callback URL dynamically, ensuring it goes to telegram_callback.php in the same directory
$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
$dir = dirname($_SERVER['REQUEST_URI']);
$callbackUrl = $protocol . "://" . $_SERVER['HTTP_HOST'] . $dir . "/telegram_callback.php?session_id=" . urlencode($sessionId);

?>
<!DOCTYPE html>
<html>
<head>
    <title>Login with Telegram</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f3f4f6; margin: 0; }
        .card { background: white; padding: 40px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); text-align: center; max-width: 400px; width: 90%; }
        h2 { color: #111827; margin-top: 0; font-size: 24px; font-weight: 700; }
        p { color: #6b7280; margin-bottom: 32px; line-height: 1.5; }
        .tg-container { display: flex; justify-content: center; }
    </style>
</head>
<body>
    <div class="card">
        <svg style="width: 64px; height: 64px; color: #0088cc; margin-bottom: 16px;" fill="currentColor" viewBox="0 0 24 24"><path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.896-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.892-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/></svg>
        <h2>Secure Authentication</h2>
        <p>Please log in with your official Telegram account to verify your identity before starting the exam.</p>
        <div class="tg-container">
            <script async src="https://telegram.org/js/telegram-widget.js?22" data-telegram-login="<?= htmlspecialchars($botUsername) ?>" data-size="large" data-auth-url="<?= htmlspecialchars($callbackUrl) ?>" data-request-access="write"></script>
        </div>
    </div>
</body>
</html>
