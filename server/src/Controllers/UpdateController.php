<?php
namespace App\Controllers;

use App\Core\Database;
use App\Core\Config;
use App\Repositories\SettingsRepository;
use App\Services\UpdateService;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;

class UpdateController extends BaseController {
    public function upload(Request $request, Response $response, array $args): Response {
        $adminId = $request->getAttribute('admin_id');
        if (!$adminId) return $this->json($response, ["error" => "Unauthorized"], 401);

        if (!class_exists('ZipArchive')) {
            return $this->json($response, ["error" => "ZipArchive extension is not enabled on this server."], 500);
        }

        $data = $request->getParsedBody() ?? [];
        $files = $request->getUploadedFiles() ?? [];

        if (!isset($files['update_zip'])) {
            return $this->json($response, ["error" => "No file uploaded or file empty."], 400);
        }

        $uploadedFile = $files['update_zip'];
        if ($uploadedFile->getError() !== UPLOAD_ERR_OK) {
            return $this->json($response, ["error" => "Upload failed. Error code: " . $uploadedFile->getError()], 400);
        }

        // Write the Slim UploadedFile to a temporary physical path for ZipArchive
        $zipPath = tempnam(sys_get_temp_dir(), 'update_');
        $uploadedFile->moveTo($zipPath);

        // Map mock $_FILES structure for UpdateService backwards compatibility
        $mockFile = [
            'error' => UPLOAD_ERR_OK,
            'tmp_name' => $zipPath
        ];

        $db = Database::getInstance();
        $rootPath = realpath(__DIR__ . '/../../');
        $updateService = new UpdateService(new SettingsRepository($db), $rootPath);

        try {
            $result = $updateService->processUpdate($mockFile, $data['new_version'] ?? null);
            @unlink($zipPath);
            return $this->json($response, $result);
        } catch (\Exception $e) {
            @unlink($zipPath);
            $code = $e->getCode() ?: 500;
            if ($code === 0) $code = 400;
            return $this->json($response, ["error" => $e->getMessage()], $code);
        }
    }
}
