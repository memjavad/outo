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
        // Validate all files in the ZIP for path traversal vulnerabilities
        for ($i = 0; $i < $zip->numFiles; $i++) {
            $entryName = $zip->getNameIndex($i);
            if (strpos($entryName, '../') !== false ||
                strpos($entryName, '..\\') !== false ||
                substr($entryName, 0, 1) === '/' ||
                preg_match('/^[a-zA-Z]:[\\\\\/]/', $entryName)) {
                $zip->close();
                throw new Exception("Insecure ZIP archive detected. Directory traversal or absolute paths are not allowed.");
            }
        }

        // Extract files manually to ensure paths are controlled
        for ($i = 0; $i < $zip->numFiles; $i++) {
            $entryName = $zip->getNameIndex($i);
            if (empty($entryName)) continue;

            $fullPath = $extractPath . '/' . $entryName;

            if (substr($entryName, -1) === '/') {
                if (!is_dir($fullPath)) {
                    mkdir($fullPath, 0755, true);
                }
            } else {
                $dir = dirname($fullPath);
                if (!is_dir($dir)) {
                    mkdir($dir, 0755, true);
                }
                copy("zip://".$zipPath."#".$entryName, $fullPath);
            }
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
