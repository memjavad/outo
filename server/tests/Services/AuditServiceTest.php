<?php
namespace Tests\Services;

use PHPUnit\Framework\TestCase;
use App\Services\AuditService;
use PDO;
use PDOStatement;
use Exception;

class AuditServiceTest extends TestCase {

    protected function setUp(): void {
        parent::setUp();
        // Set up a dummy IP address for testing
        $_SERVER['REMOTE_ADDR'] = '127.0.0.1';
    }

    protected function tearDown(): void {
        unset($_SERVER['REMOTE_ADDR']);
        parent::tearDown();
    }

    public function testLogActionWithStringDetails() {
        $mockStmt = $this->createMock(PDOStatement::class);
        $mockStmt->expects($this->once())
                 ->method('execute')
                 ->with([1, 'update_user', 'details string', '127.0.0.1'])
                 ->willReturn(true);

        $mockDb = $this->createMock(PDO::class);
        $mockDb->expects($this->once())
               ->method('prepare')
               ->with("INSERT INTO audit_log (admin_id, action, details, ip_address) VALUES (?, ?, ?, ?)")
               ->willReturn($mockStmt);

        $auditService = new AuditService($mockDb);
        $result = $auditService->logAction(1, 'update_user', 'details string');

        $this->assertTrue($result);
    }

    public function testLogActionWithArrayDetails() {
        $mockStmt = $this->createMock(PDOStatement::class);
        $detailsArray = ['key' => 'value'];
        $expectedJson = json_encode($detailsArray);

        $mockStmt->expects($this->once())
                 ->method('execute')
                 ->with([2, 'delete_post', $expectedJson, '127.0.0.1'])
                 ->willReturn(true);

        $mockDb = $this->createMock(PDO::class);
        $mockDb->expects($this->once())
               ->method('prepare')
               ->with("INSERT INTO audit_log (admin_id, action, details, ip_address) VALUES (?, ?, ?, ?)")
               ->willReturn($mockStmt);

        $auditService = new AuditService($mockDb);
        $result = $auditService->logAction(2, 'delete_post', $detailsArray);

        $this->assertTrue($result);
    }

    public function testLogActionHandlesException() {
        $mockDb = $this->createMock(PDO::class);
        $mockDb->expects($this->once())
               ->method('prepare')
               ->willThrowException(new Exception("Database connection failed"));

        $auditService = new AuditService($mockDb);

        // Hide error_log output for this test
        $tmpErrorLog = ini_get('error_log');
        ini_set('error_log', '/dev/null');

        $result = $auditService->logAction(3, 'error_action', 'error details');

        ini_set('error_log', $tmpErrorLog);

        $this->assertFalse($result);
    }
}
