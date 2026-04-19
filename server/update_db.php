<?php
// Simple Migrator Trigger Script
require __DIR__ . '/vendor/autoload.php';

use App\Core\Database;
use App\Core\Migrator;

try {
    $db = Database::getInstance();
    $migrator = new Migrator($db);
    $result = $migrator->up();

    echo "<h1>Database Schema Update Complete!</h1>";
    echo "<p>Please safely delete this file (update_db.php) from your server now.</p>";
    echo "<pre>";
    print_r($result);
    echo "</pre>";
} catch (\Exception $e) {
    echo "<h1>Error</h1>";
    echo "<p>" . $e->getMessage() . "</p>";
}
