<?php
require_once __DIR__ . '/server/vendor/autoload.php';

use App\Core\Database;

try {
    $db = Database::getInstance();
    $version = $db->query("SELECT VERSION()")->fetchColumn();
    echo "MySQL Version: " . $version . "\n";
} catch (\Exception $e) {
    echo "DB Connection failed: " . $e->getMessage() . "\n";
}
