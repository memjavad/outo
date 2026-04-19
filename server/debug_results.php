<?php
require 'vendor/autoload.php';
require 'src/Core/Database.php';

use App\Core\Database;

$db = Database::getInstance();
$stmt = $db->query("SELECT * FROM results ORDER BY id DESC LIMIT 5");
$results = $stmt->fetchAll(PDO::FETCH_ASSOC);

print_r($results);

// Also check if any fatal errors happened today
if (file_exists('error_log')) {
    echo "\n\n--- ERROR LOG ---\n";
    echo shell_exec('tail -n 20 error_log');
}
