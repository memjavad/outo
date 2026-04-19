<?php
// Ensure autoloader is available if not already loaded (e.g. when included from legacy scripts)
if (!class_exists('App\\Core\\Config')) {
    spl_autoload_register(function ($class) {
        if (strpos($class, 'App\\') === 0) {
            $file = __DIR__ . '/src/' . str_replace('\\', '/', substr($class, 4)) . '.php';
            if (file_exists($file)) {
                require_once $file;
            }
        }
    });
}

use App\Core\Config;

$host = Config::get('db_host', 'localhost');
$username = Config::get('db_user', 'root');
$password = Config::get('db_pass', '');
$dbname = Config::get('db_name', 'student_quiz_db');

try {
    // 1. Connect without database to create it if it doesn't exist
    $pdo = new PDO("mysql:host=$host;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $pdo->exec("CREATE DATABASE IF NOT EXISTS `$dbname`;");
    $pdo->exec("USE `$dbname`;");

} catch (PDOException $e) {
    die(json_encode(["error" => "Database Connection failed: " . $e->getMessage()]));
}
?>
