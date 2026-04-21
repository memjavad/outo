<?php
session_start();

// Ensure only admins can access this file directly
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'error' => 'Unauthorized access. Admins only.']);
    exit;
}

// Ensure the request method is POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'error' => 'Method not allowed. Use POST.']);
    exit;
}

require_once __DIR__ . '/../src/Core/Config.php';
require_once __DIR__ . '/../src/Core/Database.php';

use App\Core\Database;

try {
    $db = Database::getInstance();
    $newVersion = $_POST['new_version'] ?? null;
    $zipFile = $_FILES['update_zip'] ?? null;

    if (!$zipFile || $zipFile['error'] !== UPLOAD_ERR_OK) {
        echo json_encode(["status" => "error", "error" => "No valid ZIP file uploaded."]);
        exit;
    }

    $zipPath = $zipFile['tmp_name'];
    $extractPath = realpath(__DIR__ . '/../'); 

    $zip = new ZipArchive;
    if ($zip->open($zipPath) === TRUE) {
        // Validate all files in the ZIP for path traversal and absolute paths
        for ($i = 0; $i < $zip->numFiles; $i++) {
            $filename = $zip->getNameIndex($i);
            if (str_contains($filename, '../') || str_contains($filename, '..\\') || str_starts_with($filename, '/') || str_starts_with($filename, '\\')) {
                $zip->close();
                throw new Exception("Security Error: Invalid file path detected in ZIP archive.");
            }
        }

        // Extract over the main server folder
        if (!$zip->extractTo($extractPath)) {
            throw new Exception("Failed to extract files directly to the server folder.");
        }
        $zip->close();
    } else {
        throw new Exception("Failed to open the uploaded ZIP file.");
    }

    if ($newVersion) {
        $stmt = $db->prepare("INSERT INTO settings (setting_key, setting_value) VALUES ('system_version', ?) ON DUPLICATE KEY UPDATE setting_value = ?");
        $stmt->execute([$newVersion, $newVersion]);
    }
    
    echo json_encode(["status" => "success", "message" => "System updated to version " . ($newVersion ?? "current") . ". Files extracted."]);
} catch (\Exception $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "error" => "Update failed: " . $e->getMessage()]);
}
?>
