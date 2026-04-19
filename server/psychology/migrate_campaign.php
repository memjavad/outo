<?php
// C:\the ai\outo platfrom\psychology\migrate_campaign.php

// Ensure this is run from CLI for safety
if (php_sapi_name() !== 'cli') {
    die("This script can only be executed via the command line.\n");
}

// ==========================================
// VPS PRODUCTION CONFIGURATION
// ==========================================
// If uploading to a VPS, configure these credentials. You do not need the rest of the backend!
$db_host = 'localhost';
$db_user = 'root'; // Change if your VPS uses a specific user
$db_pass = '';     // Change if your VPS has a password
$db_name = 'student_quiz_app'; // Change if your VPS DB name differs

$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
$conn->set_charset("utf8mb4");

if ($conn->connect_error) {
    die("VPS Database Connection failed: " . $conn->connect_error . "\n");
}

echo "Migrating Database to support Campaign Phase 4...\n";

// 1. Add columns to quiz_results
$sql1 = "ALTER TABLE quiz_results ADD COLUMN IF NOT EXISTS earned_stars INT DEFAULT 0 AFTER score_percentage;";
$sql2 = "ALTER TABLE quiz_results ADD COLUMN IF NOT EXISTS campaign_score INT DEFAULT 0 AFTER earned_stars;";

// 2. Add stars to students table
$sql3 = "ALTER TABLE students ADD COLUMN IF NOT EXISTS stars INT DEFAULT 0 AFTER points;";

if ($conn->query($sql1) === TRUE) {
    echo "SUCCESS: Added 'earned_stars' to quiz_results.\n";
} else {
    echo "NOTICE: 'earned_stars' might already exist or error: " . $conn->error . "\n";
}

if ($conn->query($sql2) === TRUE) {
    echo "SUCCESS: Added 'campaign_score' to quiz_results.\n";
} else {
    echo "NOTICE: 'campaign_score' might already exist or error: " . $conn->error . "\n";
}

if ($conn->query($sql3) === TRUE) {
    echo "SUCCESS: Added 'stars' tracking to students table.\n";
} else {
    echo "NOTICE: 'stars' might already exist in students table or error: " . $conn->error . "\n";
}

echo "\n------ MIGRATION COMPLETE ------\n";
echo "Your Database is fully upgraded for Journey of Psychology!\n";
$conn->close();
?>
