<?php
namespace Tests\Repositories;

use PHPUnit\Framework\TestCase;
use App\Repositories\SettingsRepository;
use PDO;
use PDOStatement;

class SettingsRepositoryTest extends TestCase {

    private PDO $pdoMock;
    private PDOStatement $stmtMock;
    private SettingsRepository $repository;

    protected function setUp(): void {
        $this->pdoMock = $this->createMock(PDO::class);
        $this->stmtMock = $this->createMock(PDOStatement::class);
        $this->repository = new SettingsRepository($this->pdoMock);
    }

    public function testGetAllReturnsArray() {
        $expectedData = ['key1' => 'value1', 'key2' => 'value2'];

        $this->pdoMock->expects($this->once())
            ->method('query')
            ->with("SELECT setting_key, setting_value FROM settings")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_KEY_PAIR)
            ->willReturn($expectedData);

        $result = $this->repository->getAll();
        $this->assertEquals($expectedData, $result);
    }

    public function testGetAllReturnsEmptyArrayWhenNoSettings() {
        $this->pdoMock->expects($this->once())
            ->method('query')
            ->with("SELECT setting_key, setting_value FROM settings")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_KEY_PAIR)
            ->willReturn(false);

        $result = $this->repository->getAll();
        $this->assertEquals([], $result);
    }

    public function testGetReturnsValue() {
        $key = 'some_key';
        $expectedValue = 'some_value';

        $this->pdoMock->expects($this->once())
            ->method('prepare')
            ->with("SELECT setting_value FROM settings WHERE setting_key = ?")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with([$key])
            ->willReturn(true);

        $this->stmtMock->expects($this->once())
            ->method('fetchColumn')
            ->willReturn($expectedValue);

        $result = $this->repository->get($key);
        $this->assertEquals($expectedValue, $result);
    }

    public function testGetReturnsDefaultWhenNotFound() {
        $key = 'missing_key';
        $default = 'default_val';

        $this->pdoMock->expects($this->once())
            ->method('prepare')
            ->with("SELECT setting_value FROM settings WHERE setting_key = ?")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with([$key])
            ->willReturn(true);

        $this->stmtMock->expects($this->once())
            ->method('fetchColumn')
            ->willReturn(false);

        $result = $this->repository->get($key, $default);
        $this->assertEquals($default, $result);
    }

    public function testUpdateManySuccessfullyUpdates() {
        $data = [
            'key1' => 'val1',
            'api_key' => 'secret', // Should be skipped
            'key2' => 'val2'
        ];

        $this->pdoMock->expects($this->once())
            ->method('beginTransaction')
            ->willReturn(true);

        $this->pdoMock->expects($this->once())
            ->method('prepare')
            ->with("INSERT INTO settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = ?")
            ->willReturn($this->stmtMock);

        // We expect execute to be called twice, once for key1, once for key2. api_key should be skipped.
        $this->stmtMock->expects($this->exactly(2))
            ->method('execute')
            ->willReturnCallback(function($args) {
                $this->assertContains($args[0], ['key1', 'key2']);
                return true;
            });

        $this->pdoMock->expects($this->once())
            ->method('commit')
            ->willReturn(true);

        $result = $this->repository->updateMany($data);
        $this->assertTrue($result);
    }

    public function testUpdateManyRollsBackOnException() {
        $data = ['key1' => 'val1'];

        $this->pdoMock->expects($this->once())
            ->method('beginTransaction')
            ->willReturn(true);

        $this->pdoMock->expects($this->once())
            ->method('prepare')
            ->willThrowException(new \Exception("DB Error"));

        $this->pdoMock->expects($this->once())
            ->method('inTransaction')
            ->willReturn(true);

        $this->pdoMock->expects($this->once())
            ->method('rollBack')
            ->willReturn(true);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage("DB Error");

        $this->repository->updateMany($data);
    }
}
