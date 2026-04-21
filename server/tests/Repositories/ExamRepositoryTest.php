<?php
namespace Tests\Repositories;

use PHPUnit\Framework\TestCase;
use App\Repositories\ExamRepository;
use PDO;
use PDOStatement;

/**
 * @covers \App\Repositories\ExamRepository
 */
class ExamRepositoryTest extends TestCase {
    private ExamRepository $repository;

    public function testGetAllForAdminReturnsArray(): void {
        $stmtMock = $this->createStub(PDOStatement::class);
        $stmtMock->method('fetchAll')->willReturn([['id' => 1, 'title' => 'Test Exam']]);

        $dbMock = $this->createMock(PDO::class);
        $dbMock->expects($this->once())->method('query')->willReturn($stmtMock);
        $this->repository = new ExamRepository($dbMock);

        $result = $this->repository->getAllForAdmin();
        $this->assertIsArray($result);
        $this->assertCount(1, $result);
        $this->assertEquals('Test Exam', $result[0]['title']);
    }

    public function testGetByIdReturnsExam(): void {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())->method('execute')->with([1]);
        $stmtMock->method('fetch')->willReturn(['id' => 1, 'title' => 'Test Exam']);

        $dbMock = $this->createMock(PDO::class);
        $dbMock->expects($this->once())->method('prepare')->willReturn($stmtMock);
        $this->repository = new ExamRepository($dbMock);

        $result = $this->repository->getById(1);
        $this->assertIsArray($result);
        $this->assertEquals(1, $result['id']);
    }

    public function testGetByIdReturnsNullWhenNotFound(): void {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())->method('execute')->with([999]);
        $stmtMock->method('fetch')->willReturn(false);

        $dbMock = $this->createMock(PDO::class);
        $dbMock->expects($this->once())->method('prepare')->willReturn($stmtMock);
        $this->repository = new ExamRepository($dbMock);

        $result = $this->repository->getById(999);
        $this->assertNull($result);
    }

    public function testGetAllForTeacherReturnsArray(): void {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())->method('execute')->with([1]);
        $stmtMock->method('fetchAll')->willReturn([['id' => 1, 'title' => 'Test Exam']]);

        $dbMock = $this->createMock(PDO::class);
        $dbMock->expects($this->once())->method('prepare')->willReturn($stmtMock);
        $this->repository = new ExamRepository($dbMock);

        $result = $this->repository->getAllForTeacher(1);
        $this->assertIsArray($result);
        $this->assertCount(1, $result);
    }

    public function testGetAllActiveReturnsArray(): void {
        $stmtMock = $this->createStub(PDOStatement::class);
        $stmtMock->method('fetchAll')->willReturn([['id' => 1, 'title' => 'Test Exam']]);

        $dbMock = $this->createMock(PDO::class);
        $dbMock->expects($this->once())->method('query')->willReturn($stmtMock);
        $this->repository = new ExamRepository($dbMock);

        $result = $this->repository->getAllActive();
        $this->assertIsArray($result);
        $this->assertCount(1, $result);
    }

    public function testGetActiveByTypeReturnsArray(): void {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())->method('execute')->with(['standard']);
        $stmtMock->method('fetchAll')->willReturn([['id' => 1, 'title' => 'Test Exam']]);

        $dbMock = $this->createMock(PDO::class);
        $dbMock->expects($this->once())->method('prepare')->willReturn($stmtMock);
        $this->repository = new ExamRepository($dbMock);

        $result = $this->repository->getActiveByType('standard');
        $this->assertIsArray($result);
        $this->assertCount(1, $result);
    }

    public function testGetByTypeReturnsArray(): void {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())->method('execute')->with(['essay']);
        $stmtMock->method('fetchAll')->willReturn([['id' => 1, 'title' => 'Test Exam']]);

        $dbMock = $this->createMock(PDO::class);
        $dbMock->expects($this->once())->method('prepare')->willReturn($stmtMock);
        $this->repository = new ExamRepository($dbMock);

        $result = $this->repository->getByType('essay');
        $this->assertIsArray($result);
        $this->assertCount(1, $result);
    }

    public function testCreateReturnsInsertId(): void {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())->method('execute')->with(['Test Exam', 'essay']);

        $dbMock = $this->createMock(PDO::class);
        $dbMock->expects($this->once())->method('prepare')->willReturn($stmtMock);
        $dbMock->expects($this->once())->method('lastInsertId')->willReturn('42');
        $this->repository = new ExamRepository($dbMock);

        $result = $this->repository->create(['title' => 'Test Exam', 'exam_type' => 'essay']);
        $this->assertEquals(42, $result);
    }

    public function testUpdateReturnsTrue(): void {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())->method('execute')->with(['Updated Title', 1])->willReturn(true);

        $dbMock = $this->createMock(PDO::class);
        $dbMock->expects($this->once())->method('prepare')->willReturn($stmtMock);
        $this->repository = new ExamRepository($dbMock);

        $result = $this->repository->update(1, ['title' => 'Updated Title']);
        $this->assertTrue($result);
    }

    public function testUpdateEmptyDataReturnsTrue(): void {
        $dbMock = $this->createStub(PDO::class);
        $this->repository = new ExamRepository($dbMock);
        $result = $this->repository->update(1, []);
        $this->assertTrue($result);
    }

    public function testDeleteReturnsTrue(): void {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())->method('execute')->with([1])->willReturn(true);

        $dbMock = $this->createMock(PDO::class);
        $dbMock->expects($this->once())->method('prepare')->willReturn($stmtMock);
        $this->repository = new ExamRepository($dbMock);

        $result = $this->repository->delete(1);
        $this->assertTrue($result);
    }
}
