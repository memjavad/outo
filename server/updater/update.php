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
        // Extract over the main server folder safely
        $realExtractPath = realpath($extractPath);
        if ($realExtractPath === false) {
            $zip->close();
            throw new Exception("Invalid root path.");
        }

        for ($i = 0; $i < $zip->numFiles; $i++) {
            $entryName = $zip->getNameIndex($i);

            // Basic sanitization
            if (strpos($entryName, '../') !== false || strpos($entryName, '..\\') !== false || strpos($entryName, '/') === 0) {
                $zip->close();
                throw new Exception("Security Error: Path traversal detected.");
            }

            $fullPath = $extractPath . '/' . $entryName;

            if (substr($entryName, -1) === '/') {
                if (!is_dir($fullPath)) mkdir($fullPath, 0755, true);
                $realDir = realpath($fullPath);
            } else {
                $dir = dirname($fullPath);
                if (!is_dir($dir)) mkdir($dir, 0755, true);
                $realDir = realpath($dir);
            }

            if ($realDir === false || (strpos($realDir, $realExtractPath . DIRECTORY_SEPARATOR) !== 0 && $realDir !== $realExtractPath)) {
                $zip->close();
                throw new Exception("Security Error: Path traversal detected outside root.");
            }

            if (substr($entryName, -1) !== '/') {
                if (!copy("zip://" . $zipPath . "#" . $entryName, $fullPath)) {
                    $zip->close();
                    throw new Exception("Extraction failed for file: " . $entryName);
                }
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
