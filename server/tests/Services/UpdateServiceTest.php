<?php
namespace Tests\Services;

use App\Services\UpdateService;
use App\Repositories\SettingsRepository;
use PHPUnit\Framework\TestCase;
use Exception;

class UpdateServiceTest extends TestCase {
    private $settingsRepoMock;
    private $updateService;
    private $tempDir;

    protected function setUp(): void {
        parent::setUp();

        $this->settingsRepoMock = $this->createMock(SettingsRepository::class);

        $this->tempDir = sys_get_temp_dir() . '/update_test_' . uniqid();
        mkdir($this->tempDir, 0777, true);

        $this->updateService = new UpdateService($this->settingsRepoMock, $this->tempDir);
    }

    protected function tearDown(): void {
        $this->removeDirectory($this->tempDir);
        parent::tearDown();
    }

    private function removeDirectory($dir) {
        if (!is_dir($dir)) return;
        $files = array_diff(scandir($dir), ['.', '..']);
        foreach ($files as $file) {
            $path = "$dir/$file";
            is_dir($path) ? $this->removeDirectory($path) : unlink($path);
        }
        rmdir($dir);
    }

    public function testProcessUpdateFailsOnUploadError() {
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Upload failed. Error code: 1');

        $file = [
            'name' => 'test.zip',
            'type' => 'application/zip',
            'tmp_name' => '/tmp/dummy',
            'error' => UPLOAD_ERR_INI_SIZE,
            'size' => 123
        ];

        $this->updateService->processUpdate($file, '1.0.1');
    }

    public function testProcessUpdateFailsOnInvalidZip() {
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Failed to open ZIP file');

        $invalidZipPath = $this->tempDir . '/invalid.zip';
        file_put_contents($invalidZipPath, 'not a zip file');

        $file = [
            'name' => 'test.zip',
            'type' => 'application/zip',
            'tmp_name' => $invalidZipPath,
            'error' => UPLOAD_ERR_OK,
            'size' => filesize($invalidZipPath)
        ];

        $this->updateService->processUpdate($file, '1.0.1');
    }

    public function testProcessUpdateExtractsFlatZipAndUpdatesVersion() {
        $zipPath = $this->tempDir . '/valid_flat.zip';
        $zip = new \ZipArchive();
        $this->assertTrue($zip->open($zipPath, \ZipArchive::CREATE));
        $zip->addFromString('file1.txt', 'content1');
        $zip->addFromString('dir1/file2.txt', 'content2');
        $zip->close();

        $file = [
            'name' => 'valid_flat.zip',
            'type' => 'application/zip',
            'tmp_name' => $zipPath,
            'error' => UPLOAD_ERR_OK,
            'size' => filesize($zipPath)
        ];

        $this->settingsRepoMock->expects($this->once())
            ->method('updateMany')
            ->with(['system_version' => '1.0.2']);

        $result = $this->updateService->processUpdate($file, '1.0.2');

        $this->assertEquals('success', $result['status']);
        $this->assertStringContainsString('1.0.2', $result['message']);

        // Check if files are extracted properly
        $this->assertFileExists($this->tempDir . '/file1.txt');
        $this->assertEquals('content1', file_get_contents($this->tempDir . '/file1.txt'));
        $this->assertFileExists($this->tempDir . '/dir1/file2.txt');
        $this->assertEquals('content2', file_get_contents($this->tempDir . '/dir1/file2.txt'));
    }

    public function testProcessUpdateExtractsNestedZipWithoutVersion() {
        $zipPath = $this->tempDir . '/valid_nested.zip';
        $zip = new \ZipArchive();
        $this->assertTrue($zip->open($zipPath, \ZipArchive::CREATE));
        $zip->addFromString('root_dir/file1.txt', 'content1');
        $zip->addFromString('root_dir/dir1/file2.txt', 'content2');
        $zip->close();

        $file = [
            'name' => 'valid_nested.zip',
            'type' => 'application/zip',
            'tmp_name' => $zipPath,
            'error' => UPLOAD_ERR_OK,
            'size' => filesize($zipPath)
        ];

        $this->settingsRepoMock->expects($this->never())
            ->method('updateMany');

        $result = $this->updateService->processUpdate($file, null);

        $this->assertEquals('success', $result['status']);
        $this->assertStringContainsString('unknown', $result['message']);

        // Check if files are extracted properly (without the root dir)
        $this->assertFileExists($this->tempDir . '/file1.txt');
        $this->assertEquals('content1', file_get_contents($this->tempDir . '/file1.txt'));
        $this->assertFileExists($this->tempDir . '/dir1/file2.txt');
        $this->assertEquals('content2', file_get_contents($this->tempDir . '/dir1/file2.txt'));
    }
}
