<?php
require_once __DIR__ . '/db_connect.php';
$db = App\Core\Database::getInstance();
$stmt = $db->query("SELECT id, name, phone, email, enrolled, password_hash FROM students");
$students = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode($students, JSON_PRETTY_PRINT);
