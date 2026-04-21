<?php
namespace Tests\Repositories;

use PHPUnit\Framework\TestCase;
use App\Repositories\SessionRepository;
use PDO;
use PDOStatement;

class SessionRepositoryTest extends TestCase {
    private $dbMock;
    private $stmtMock;
    private $repository;

    protected function setUp(): void {
        $this->dbMock = $this->createMock(PDO::class);
        $this->stmtMock = $this->createMock(PDOStatement::class);
        $this->repository = new SessionRepository($this->dbMock);
    }

    public function testCreateSession() {
        $this->dbMock->expects($this->once())
            ->method('prepare')
            ->with("INSERT INTO active_sessions (student_name, exam_id, total_questions, ip_address) VALUES (?, ?, ?, ?)")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with(['John Doe', 1, 10, '127.0.0.1']);

        $this->repository->createSession('John Doe', 1, 10, '127.0.0.1');
    }

    public function testUpdateHeartbeat() {
        $this->dbMock->expects($this->once())
            ->method('prepare')
            ->with("UPDATE active_sessions SET current_question = ?, answered_count = ?, last_heartbeat = NOW() WHERE student_name = ? AND status = 'active'")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with([5, 4, 'John Doe']);

        $this->repository->updateHeartbeat('John Doe', 5, 4);
    }

    public function testCleanStaleSessions() {
        $this->dbMock->expects($this->once())
            ->method('exec')
            ->with("UPDATE active_sessions SET status = 'abandoned' WHERE status = 'active' AND last_heartbeat < DATE_SUB(NOW(), INTERVAL 5 MINUTE)");

        $this->repository->cleanStaleSessions();
    }

    public function testGetActiveSessions() {
        $expectedSessions = [
            ['id' => 1, 'student_name' => 'John Doe', 'status' => 'active'],
            ['id' => 2, 'student_name' => 'Jane Smith', 'status' => 'active']
        ];

        $this->dbMock->expects($this->once())
            ->method('query')
            ->with("SELECT * FROM active_sessions WHERE status = 'active' ORDER BY last_heartbeat DESC")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn($expectedSessions);

        $result = $this->repository->getActiveSessions();
        $this->assertEquals($expectedSessions, $result);
    }
}
