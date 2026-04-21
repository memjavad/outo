<?php
namespace Tests\Repositories;

use PHPUnit\Framework\TestCase;
use App\Repositories\SettingsRepository;
use PDO;
use PDOStatement;

class SettingsRepositoryTest extends TestCase {
    private $db;
    private $settingsRepo;

    protected function setUp(): void {
        $this->db = $this->createMock(PDO::class);
        $this->settingsRepo = new SettingsRepository($this->db);
    }

    public function testGetAllReturnsEmptyArrayWhenNoSettings() {
        $stmt = $this->createMock(PDOStatement::class);
        $stmt->expects($this->once())
             ->method('fetchAll')
             ->with(PDO::FETCH_KEY_PAIR)
             ->willReturn([]); // Changed from false to []

        $this->db->expects($this->once())
                 ->method('query')
                 ->with("SELECT setting_key, setting_value FROM settings")
                 ->willReturn($stmt);

        $result = $this->settingsRepo->getAll();
        $this->assertEquals([], $result);
    }

    public function testGetAllReturnsSettings() {
        $expected = ['site_name' => 'My Site', 'theme' => 'dark'];

        $stmt = $this->createMock(PDOStatement::class);
        $stmt->expects($this->once())
             ->method('fetchAll')
             ->with(PDO::FETCH_KEY_PAIR)
             ->willReturn($expected);

        $this->db->expects($this->once())
                 ->method('query')
                 ->with("SELECT setting_key, setting_value FROM settings")
                 ->willReturn($stmt);

        $result = $this->settingsRepo->getAll();
        $this->assertEquals($expected, $result);
    }

    public function testGetReturnsSettingValue() {
        $stmt = $this->createMock(PDOStatement::class);
        $stmt->expects($this->once())
             ->method('execute')
             ->with(['site_name'])
             ->willReturn(true);
        $stmt->expects($this->once())
             ->method('fetchColumn')
             ->willReturn('My Site');

        $this->db->expects($this->once())
                 ->method('prepare')
                 ->with("SELECT setting_value FROM settings WHERE setting_key = ?")
                 ->willReturn($stmt);

        $result = $this->settingsRepo->get('site_name');
        $this->assertEquals('My Site', $result);
    }

    public function testGetReturnsDefaultValueWhenSettingNotFound() {
        $stmt = $this->createMock(PDOStatement::class);
        $stmt->expects($this->once())
             ->method('execute')
             ->with(['missing_key'])
             ->willReturn(true);
        $stmt->expects($this->once())
             ->method('fetchColumn')
             ->willReturn(false);

        $this->db->expects($this->once())
                 ->method('prepare')
                 ->with("SELECT setting_value FROM settings WHERE setting_key = ?")
                 ->willReturn($stmt);

        $result = $this->settingsRepo->get('missing_key', 'default_val');
        $this->assertEquals('default_val', $result);
    }

    public function testUpdateManySuccessfullyUpdatesSettings() {
        $data = ['site_name' => 'New Site', 'theme' => 'light'];

        $this->db->expects($this->once())->method('beginTransaction');

        $stmt = $this->createMock(PDOStatement::class);

        // Use a callback to assert multiple consecutive calls since withConsecutive was removed
        $callIndex = 0;
        $stmt->expects($this->exactly(2))
             ->method('execute')
             ->willReturnCallback(function ($args) use (&$callIndex) {
                 if ($callIndex === 0) {
                     $this->assertEquals(['site_name', 'New Site', 'New Site'], $args);
                 } else if ($callIndex === 1) {
                     $this->assertEquals(['theme', 'light', 'light'], $args);
                 }
                 $callIndex++;
                 return true;
             });

        $this->db->expects($this->once())
                 ->method('prepare')
                 ->with("INSERT INTO settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = ?")
                 ->willReturn($stmt);

        $this->db->expects($this->once())->method('commit');

        $result = $this->settingsRepo->updateMany($data);
        $this->assertTrue($result);
    }

    public function testUpdateManySkipsProtectedKeys() {
        $data = ['site_name' => 'New Site', 'api_key' => 'secret'];

        $this->db->expects($this->once())->method('beginTransaction');

        $stmt = $this->createMock(PDOStatement::class);
        // Execute should only be called once, skipping 'api_key'
        $stmt->expects($this->once())
             ->method('execute')
             ->with(['site_name', 'New Site', 'New Site'])
             ->willReturn(true);

        $this->db->expects($this->once())
                 ->method('prepare')
                 ->with("INSERT INTO settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = ?")
                 ->willReturn($stmt);

        $this->db->expects($this->once())->method('commit');

        $result = $this->settingsRepo->updateMany($data, ['api_key']);
        $this->assertTrue($result);
    }

    public function testUpdateManyRollsBackOnException() {
        $data = ['site_name' => 'New Site'];

        $this->db->expects($this->once())->method('beginTransaction');
        $this->db->expects($this->once())->method('inTransaction')->willReturn(true);
        $this->db->expects($this->once())->method('rollBack');

        $stmt = $this->createMock(PDOStatement::class);
        $stmt->expects($this->once())
             ->method('execute')
             ->willThrowException(new \Exception('Database error'));

        $this->db->expects($this->once())
                 ->method('prepare')
                 ->willReturn($stmt);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Database error');

        $this->settingsRepo->updateMany($data);
    }
}
