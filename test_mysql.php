<?php
require_once __DIR__ . '/server/vendor/autoload.php';

use App\Core\Database;

try {
    $db = Database::getInstance();
    $db->query("CREATE TABLE IF NOT EXISTS dummy_test (id INT PRIMARY KEY, is_graded TINYINT, created_at DATETIME)");
    $db->query("INSERT IGNORE INTO dummy_test VALUES (1, 0, NOW())");
    $res = $db->query("
        SELECT * FROM dummy_test
        WHERE is_graded = 0
           OR id IN (SELECT id FROM (SELECT id FROM dummy_test ORDER BY created_at DESC LIMIT 10) as temp)
    ")->fetchAll();
    echo "MySQL compatible: " . count($res) . "\n";
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
