<?php
namespace Tests\Repositories;

use PHPUnit\Framework\TestCase;
use App\Repositories\SessionRepository;
use PDO;
use PDOStatement;

class SessionRepositoryTest extends TestCase {

    private $pdoMock;
    private $stmtMock;
    private $repository;

    protected function setUp(): void {
        $this->pdoMock = $this->createMock(PDO::class);
        $this->stmtMock = $this->createMock(PDOStatement::class);
        $this->repository = new SessionRepository($this->pdoMock);
    }

    public function testCreateSession() {
        $studentName = "John Doe";
        $examId = 1;
        $totalQuestions = 10;
        $ipAddress = "127.0.0.1";

        $this->pdoMock->expects($this->once())
             ->method('prepare')
             ->with("INSERT INTO active_sessions (student_name, exam_id, total_questions, ip_address) VALUES (?, ?, ?, ?)")
             ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
             ->method('execute')
             ->with([$studentName, $examId, $totalQuestions, $ipAddress]);

        $this->repository->createSession($studentName, $examId, $totalQuestions, $ipAddress);
    }

    public function testUpdateHeartbeat() {
        $studentName = "John Doe";
        $currentQuestion = 3;
        $answeredCount = 2;

        $this->pdoMock->expects($this->once())
             ->method('prepare')
             ->with("UPDATE active_sessions SET current_question = ?, answered_count = ?, last_heartbeat = NOW() WHERE student_name = ? AND status = 'active'")
             ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
             ->method('execute')
             ->with([$currentQuestion, $answeredCount, $studentName]);

        $this->repository->updateHeartbeat($studentName, $currentQuestion, $answeredCount);
    }

    public function testCleanStaleSessions() {
        $this->pdoMock->expects($this->once())
             ->method('exec')
             ->with("UPDATE active_sessions SET status = 'abandoned' WHERE status = 'active' AND last_heartbeat < DATE_SUB(NOW(), INTERVAL 5 MINUTE)");

        $this->repository->cleanStaleSessions();
    }

    public function testGetActiveSessions() {
        $expectedResult = [
            ['id' => 1, 'student_name' => 'John Doe', 'status' => 'active']
        ];

        $this->pdoMock->expects($this->once())
             ->method('query')
             ->with("SELECT * FROM active_sessions WHERE status = 'active' ORDER BY last_heartbeat DESC")
             ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
             ->method('fetchAll')
             ->with(PDO::FETCH_ASSOC)
             ->willReturn($expectedResult);

        $result = $this->repository->getActiveSessions();
        $this->assertEquals($expectedResult, $result);
    }
}
