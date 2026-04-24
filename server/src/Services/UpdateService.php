<?php
namespace App\Services;

use App\Repositories\SettingsRepository;
use ZipArchive;
use Exception;

class UpdateService {
    private SettingsRepository $settingsRepo;
    private string $rootPath;

    public function __construct(SettingsRepository $settingsRepo, string $rootPath) {
        $this->settingsRepo = $settingsRepo;
        $this->rootPath = $rootPath;
    }

    public function processUpdate(array $file, ?string $newVersion): array {
        if (!class_exists('ZipArchive')) {
            throw new Exception("ZipArchive extension is not enabled on this server.");
        }

        if ($file['error'] !== UPLOAD_ERR_OK) {
            throw new Exception("Upload failed. Error code: " . $file['error']);
        }

        $zipPath = $file['tmp_name'];
        $zip = new ZipArchive;

        if ($zip->open($zipPath) !== TRUE) {
            throw new Exception("Failed to open ZIP file");
        }

        $firstFileName = $zip->getNameIndex(0);
        $hasRootDir = false;
        $rootDirName = '';
        
        if ($firstFileName && strpos($firstFileName, '/') !== false) {
            $parts = explode('/', $firstFileName);
            $rootDirName = $parts[0] . '/';
            $hasRootDir = true;
            
            for ($i = 0; $i < $zip->numFiles; $i++) {
                if (strpos($zip->getNameIndex($i), $rootDirName) !== 0) {
                    $hasRootDir = false;
                    break;
                }
            }
        }

        if ($hasRootDir) {
            for ($i = 0; $i < $zip->numFiles; $i++) {
                $entryName = $zip->getNameIndex($i);
                $targetFileName = substr($entryName, strlen($rootDirName));
                if (empty($targetFileName)) continue;
                
                $fullPath = $this->rootPath . '/' . $targetFileName;
                if (substr($entryName, -1) === '/') {
                    if (!is_dir($fullPath) && !mkdir($fullPath, 0755, true)) {
                        $zip->close();
                        throw new Exception("Extraction failed: could not create directory " . $fullPath);
                    }
                } else {
                    $dir = dirname($fullPath);
                    if (!is_dir($dir) && !mkdir($dir, 0755, true)) {
                        $zip->close();
                        throw new Exception("Extraction failed: could not create directory " . $dir);
                    }
                    $fileData = $zip->getFromIndex($i);
                    if ($fileData === false) {
                        $zip->close();
                        throw new Exception("Extraction failed: could not read file " . $entryName . " from ZIP");
                    }
                    if (file_put_contents($fullPath, $fileData) === false) {
                        $zip->close();
                        throw new Exception("Extraction failed: could not write file " . $fullPath);
                    }
                }
            }
        } else {
            for ($i = 0; $i < $zip->numFiles; $i++) {
                $entryName = $zip->getNameIndex($i);

                // Prevent Zip Slip / Path Traversal
                if (empty($entryName) || strpos($entryName, '../') !== false || strpos($entryName, '..\\') !== false || substr($entryName, 0, 1) === '/') {
                    continue; // Skip invalid or dangerous paths
                }

                $fullPath = $this->rootPath . '/' . $entryName;
                if (substr($entryName, -1) === '/') {
                    if (!is_dir($fullPath) && !mkdir($fullPath, 0755, true)) {
                        $zip->close();
                        throw new Exception("Extraction failed: could not create directory " . $fullPath);
                    }
                } else {
                    $dir = dirname($fullPath);
                    if (!is_dir($dir) && !mkdir($dir, 0755, true)) {
                        $zip->close();
                        throw new Exception("Extraction failed: could not create directory " . $dir);
                    }
                    $fileData = $zip->getFromIndex($i);
                    if ($fileData === false) {
                        $zip->close();
                        throw new Exception("Extraction failed: could not read file " . $entryName . " from ZIP");
                    }
                    if (file_put_contents($fullPath, $fileData) === false) {
                        $zip->close();
                        throw new Exception("Extraction failed: could not write file " . $fullPath);
                    }
                }
            }
        }
        
        $zip->close();

        if ($newVersion) {
            $this->settingsRepo->update('system_version', $newVersion);
        }

        return [
            "status" => "success", 
            "message" => "System updated successfully to v" . ($newVersion ?? 'unknown')
        ];
    }
}
