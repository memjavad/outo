<?php
// This runs through the live Apache Web Server via HTTP to bypass missing CLI drivers
require 'vendor/autoload.php';
require 'src/Core/Database.php';

use App\Core\Database;

try {
    $db = Database::getInstance();
    
    // 1. Ensure students has 'stars'
    try {
        $db->exec("ALTER TABLE students ADD COLUMN stars INT DEFAULT 0");
        echo "[+] Added 'stars' column to students table.\n";
    } catch (\PDOException $e) {
        $msg = $e->getMessage();
        if (strpos($msg, 'Duplicate column name') !== false) {
             echo "[=] Column 'stars' already exists in students.\n";
        } else {
             echo "[-] Error adding 'stars': $msg\n";
        }
    }

    echo "\n\nMigration routine finished safely.";
} catch (\Exception $e) {
    echo "Fatal Error: " . $e->getMessage();
}
