<?php
if (file_exists(__DIR__ . '/vendor/autoload.php')) {
    require_once __DIR__ . '/vendor/autoload.php';
}

spl_autoload_register(function ($class) {
    if (strpos($class, 'App\\') === 0) {
        $file = __DIR__ . '/src/' . str_replace('\\', '/', substr($class, 4)) . '.php';
        if (file_exists($file)) {
            require_once $file;
        }
    }
});

session_start();

// CSRF Token generation
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

// Handle Language Switch
if (isset($_GET['lang'])) {
    $_SESSION['lang'] = in_array($_GET['lang'], ['en', 'ar']) ? $_GET['lang'] : 'en';
    header("Location: index.php");
    exit();
}

$controller = new App\Controllers\DashboardController();

if (isset($_GET['logout'])) {
    $controller->logout();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $controller->handlePost($_POST, $_FILES);
}

$controller->index();
?>