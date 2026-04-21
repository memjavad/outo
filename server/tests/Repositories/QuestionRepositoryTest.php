<?php
namespace Tests\Repositories;

use PHPUnit\Framework\TestCase;
use App\Repositories\QuestionRepository;
use PDO;
use PDOStatement;

class QuestionRepositoryTest extends TestCase {
    private $pdoMock;
    private $repo;

    protected function setUp(): void {
        $this->pdoMock = $this->createMock(PDO::class);
        $this->repo = new QuestionRepository($this->pdoMock);
    }

    public function testGetSummary() {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn([['id' => 1, 'text' => 'Q1']]);

        $this->pdoMock->expects($this->once())
            ->method('query')
            ->with("SELECT * FROM questions")
            ->willReturn($stmtMock);

        $result = $this->repo->getSummary();
        $this->assertCount(1, $result);
        $this->assertEquals('Q1', $result[0]['text']);
    }

    public function testGetSummaryEmpty() {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn([]);

        $this->pdoMock->expects($this->once())
            ->method('query')
            ->with("SELECT * FROM questions")
            ->willReturn($stmtMock);

        $result = $this->repo->getSummary();
        $this->assertIsArray($result);
        $this->assertEmpty($result);
    }

    public function testGetSummaryByDomain() {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())
            ->method('execute')
            ->with(['math']);
        $stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn([['id' => 2, 'domain' => 'math']]);

        $this->pdoMock->expects($this->once())
            ->method('prepare')
            ->with("SELECT * FROM questions WHERE domain = ?")
            ->willReturn($stmtMock);

        $result = $this->repo->getSummaryByDomain('math');
        $this->assertCount(1, $result);
        $this->assertEquals('math', $result[0]['domain']);
    }

    public function testGetByExamId() {
        $repoMock = $this->getMockBuilder(QuestionRepository::class)
            ->setConstructorArgs([$this->pdoMock])
            ->onlyMethods(['getOptions'])
            ->getMock();

        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())
            ->method('execute')
            ->with([1]);
        $stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn([['id' => 1, 'text' => 'Q1']]);

        $this->pdoMock->expects($this->once())
            ->method('prepare')
            ->with("SELECT * FROM questions WHERE exam_id = ? ORDER BY created_at ASC")
            ->willReturn($stmtMock);

        $repoMock->expects($this->once())
            ->method('getOptions')
            ->with(1)
            ->willReturn([['id' => 1, 'text' => 'Opt 1']]);

        $result = $repoMock->getByExamId(1, false);
        $this->assertCount(1, $result);
        $this->assertEquals('Q1', $result[0]['text']);
        $this->assertArrayHasKey('options', $result[0]);
        $this->assertCount(1, $result[0]['options']);
    }

    public function testGetByExamIdRandomize() {
        $repoMock = $this->getMockBuilder(QuestionRepository::class)
            ->setConstructorArgs([$this->pdoMock])
            ->onlyMethods(['getOptions'])
            ->getMock();

        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())
            ->method('execute')
            ->with([1]);
        $stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn([['id' => 1, 'text' => 'Q1']]);

        $this->pdoMock->expects($this->once())
            ->method('prepare')
            ->with("SELECT * FROM questions WHERE exam_id = ? ORDER BY RAND()")
            ->willReturn($stmtMock);

        $repoMock->expects($this->once())
            ->method('getOptions')
            ->with(1)
            ->willReturn([]);

        $result = $repoMock->getByExamId(1, true);
        $this->assertCount(1, $result);
    }

    public function testGetAll() {
        $repoMock = $this->getMockBuilder(QuestionRepository::class)
            ->setConstructorArgs([$this->pdoMock])
            ->onlyMethods(['getOptions'])
            ->getMock();

        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn([['id' => 1, 'text' => 'Q1'], ['id' => 2, 'text' => 'Q2']]);

        $this->pdoMock->expects($this->once())
            ->method('query')
            ->with("SELECT * FROM questions ORDER BY created_at ASC")
            ->willReturn($stmtMock);

        $repoMock->expects($this->exactly(2))
            ->method('getOptions')
            ->willReturnMap([
                [1, [['id' => 1, 'text' => 'Opt 1']]],
                [2, [['id' => 2, 'text' => 'Opt 2']]]
            ]);

        $result = $repoMock->getAll(false);
        $this->assertCount(2, $result);
        $this->assertArrayHasKey('options', $result[0]);
        $this->assertArrayHasKey('options', $result[1]);
    }

    public function testGetAllRandomize() {
        $repoMock = $this->getMockBuilder(QuestionRepository::class)
            ->setConstructorArgs([$this->pdoMock])
            ->onlyMethods(['getOptions'])
            ->getMock();

        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn([['id' => 1, 'text' => 'Q1']]);

        $this->pdoMock->expects($this->once())
            ->method('query')
            ->with("SELECT * FROM questions ORDER BY RAND()")
            ->willReturn($stmtMock);

        $repoMock->expects($this->once())
            ->method('getOptions')
            ->with(1)
            ->willReturn([]);

        $result = $repoMock->getAll(true);
        $this->assertCount(1, $result);
    }

    public function testGetOptions() {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())
            ->method('execute')
            ->with([1]);
        $stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn([['id' => 1, 'option_text' => 'Opt 1']]);

        $this->pdoMock->expects($this->once())
            ->method('prepare')
            ->with("SELECT * FROM options WHERE question_id = ? ORDER BY option_index ASC")
            ->willReturn($stmtMock);

        $result = $this->repo->getOptions(1);
        $this->assertCount(1, $result);
        $this->assertEquals('Opt 1', $result[0]['option_text']);
    }

    public function testCreateQuestion() {
        $data = ['text' => 'New Q', 'exam_id' => 1];

        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())
            ->method('execute')
            ->with(['New Q', 1]);

        $this->pdoMock->expects($this->once())
            ->method('prepare')
            ->with("INSERT INTO questions (text, exam_id) VALUES (?, ?)")
            ->willReturn($stmtMock);

        $this->pdoMock->expects($this->once())
            ->method('lastInsertId')
            ->willReturn('5');

        $result = $this->repo->createQuestion($data);
        $this->assertEquals(5, $result);
        $this->assertIsInt($result);
    }

    public function testCreateOption() {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())
            ->method('execute')
            ->with([1, 'Opt text', 0])
            ->willReturn(true);

        $this->pdoMock->expects($this->once())
            ->method('prepare')
            ->with("INSERT INTO options (question_id, option_text, option_index) VALUES (?, ?, ?)")
            ->willReturn($stmtMock);

        $result = $this->repo->createOption(1, 'Opt text', 0);
        $this->assertTrue($result);
    }

    public function testUpdateQuestion() {
        $data = ['text' => 'Updated Q', 'domain' => 'science'];

        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())
            ->method('execute')
            ->with(['Updated Q', 'science', 1])
            ->willReturn(true);

        $this->pdoMock->expects($this->once())
            ->method('prepare')
            ->with("UPDATE questions SET text = ?, domain = ? WHERE id = ?")
            ->willReturn($stmtMock);

        $result = $this->repo->updateQuestion(1, $data);
        $this->assertTrue($result);
    }

    public function testUpdateQuestionEmptyData() {
        $result = $this->repo->updateQuestion(1, []);
        $this->assertTrue($result);
    }

    public function testDeleteOptions() {
        $stmtMock = $this->createMock(PDOStatement::class);
        $stmtMock->expects($this->once())
            ->method('execute')
            ->with([1])
            ->willReturn(true);

        $this->pdoMock->expects($this->once())
            ->method('prepare')
            ->with("DELETE FROM options WHERE question_id = ?")
            ->willReturn($stmtMock);

        $result = $this->repo->deleteOptions(1);
        $this->assertTrue($result);
    }
}
