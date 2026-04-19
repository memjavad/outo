<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

spl_autoload_register(function ($class) {
    if (strpos($class, 'App\\') === 0) {
        $file = __DIR__ . '/src/' . str_replace('\\', '/', substr($class, 4)) . '.php';
        echo "Autoloading: $class -> $file ... ";
        if (file_exists($file)) {
            require_once $file;
            echo "OK\n";
        } else {
            echo "FAILED\n";
        }
    }
});

session_start();

use App\Core\Database;
use App\Core\Config;

try {
    echo "Connecting to DB...\n";
    $pdo = Database::getInstance();
    echo "Connected.\n";

    echo "Checking 'admins' table...\n";
    $count = $pdo->query("SELECT COUNT(*) FROM admins")->fetchColumn();
    echo "Admins count: $count\n";

    echo "Attempting to instantiate DashboardController...\n";
    $controller = new App\Controllers\DashboardController();
    echo "Instantiated.\n";

    echo "Running index()...\n";
    $controller->index();
    echo "Done.\n";
} catch (Exception $e) {
    echo "\nFATAL ERROR: " . $e->getMessage() . "\n";
    echo "Trace:\n" . $e->getTraceAsString() . "\n";
} catch (Error $e) {
    echo "\nFATAL ERROR (Runtime): " . $e->getMessage() . "\n";
    echo "Trace:\n" . $e->getTraceAsString() . "\n";
}
?>
