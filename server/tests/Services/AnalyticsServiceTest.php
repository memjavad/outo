<?php
namespace Tests\Services;

use PHPUnit\Framework\TestCase;
use App\Services\AnalyticsService;
use App\Core\Database;
use ReflectionClass;

// Mocks the constructor of Database just for this test
class AnalyticsServiceTest extends TestCase {
    private $dbMock;
    private $analyticsService;

    protected function setUp(): void {
        parent::setUp();

        $this->dbMock = $this->createMock(\PDO::class);

        // We can't instantiate AnalyticsService normally because it calls Database::getInstance()
        // which connects to the real DB. We bypass the constructor.
        $reflection = new ReflectionClass(AnalyticsService::class);
        $this->analyticsService = $reflection->newInstanceWithoutConstructor();

        $dbProperty = $reflection->getProperty('db');
        $dbProperty->setAccessible(true);
        $dbProperty->setValue($this->analyticsService, $this->dbMock);
    }

    public function testGetExamKPIsReturnsCorrectData() {
        $stmtMock = $this->createMock(\PDOStatement::class);
        $stmtMock->expects($this->once())
                 ->method('execute')
                 ->with([1]);
        $stmtMock->expects($this->once())
                 ->method('fetch')
                 ->with(\PDO::FETCH_ASSOC)
                 ->willReturn([
                     'total_taken' => 10,
                     'average_score' => 75.5,
                     'average_time_seconds' => 120.3,
                     'passed_count' => 6
                 ]);

        $this->dbMock->expects($this->once())
                     ->method('prepare')
                     ->willReturn($stmtMock);

        $result = $this->analyticsService->getExamKPIs(1);

        $this->assertEquals([
            'total_students' => 10,
            'average_score' => 75.5,
            'average_time_seconds' => 120.0,
            'pass_rate' => 60.0
        ], $result);
    }
    public function testGetExamKPIsHandlesZeroStudents() {
        $stmtMock = $this->createMock(\PDOStatement::class);
        $stmtMock->expects($this->once())
                 ->method('execute')
                 ->with([2]);
        $stmtMock->expects($this->once())
                 ->method('fetch')
                 ->with(\PDO::FETCH_ASSOC)
                 ->willReturn([
                     'total_taken' => 0,
                     'average_score' => null,
                     'average_time_seconds' => null,
                     'passed_count' => 0
                 ]);

        $this->dbMock->expects($this->once())
                     ->method('prepare')
                     ->willReturn($stmtMock);

        $result = $this->analyticsService->getExamKPIs(2);

        $this->assertEquals([
            'total_students' => 0,
            'average_score' => 0.0,
            'average_time_seconds' => 0.0,
            'pass_rate' => 0.0
        ], $result);
    }
    public function testGetDistractorAnalysisReturnsCorrectData() {
        $stmtMock = $this->createMock(\PDOStatement::class);
        $stmtMock->expects($this->once())
                 ->method('execute')
                 ->with([1]);
        $stmtMock->expects($this->once())
                 ->method('fetchAll')
                 ->with(\PDO::FETCH_ASSOC)
                 ->willReturn([
                     [
                         'question_id' => 10,
                         'question_text' => 'What is 2+2?',
                         'selected_option_index' => 0,
                         'pick_count' => 5
                     ],
                     [
                         'question_id' => 10,
                         'question_text' => 'What is 2+2?',
                         'selected_option_index' => 1,
                         'pick_count' => 15
                     ],
                     [
                         'question_id' => 11,
                         'question_text' => 'What is the capital of France?',
                         'selected_option_index' => null,
                         'pick_count' => 2
                     ]
                 ]);

        $this->dbMock->expects($this->once())
                     ->method('prepare')
                     ->willReturn($stmtMock);

        $result = $this->analyticsService->getDistractorAnalysis(1);

        $this->assertEquals([
            [
                'question_id' => 10,
                'question_text' => 'What is 2+2?',
                'total_answers' => 20,
                'distractors' => [
                    ['option_index' => 0, 'percentage' => 25.0],
                    ['option_index' => 1, 'percentage' => 75.0]
                ]
            ],
            [
                'question_id' => 11,
                'question_text' => 'What is the capital of France?',
                'total_answers' => 2,
                'distractors' => [
                    ['option_index' => -1, 'percentage' => 100.0]
                ]
            ]
        ], $result);
    }
    public function testGetDistractorAnalysisHandlesNoData() {
        $stmtMock = $this->createMock(\PDOStatement::class);
        $stmtMock->expects($this->once())
                 ->method('execute')
                 ->with([3]);
        $stmtMock->expects($this->once())
                 ->method('fetchAll')
                 ->with(\PDO::FETCH_ASSOC)
                 ->willReturn([]);

        $this->dbMock->expects($this->once())
                     ->method('prepare')
                     ->willReturn($stmtMock);

        $result = $this->analyticsService->getDistractorAnalysis(3);

        $this->assertEquals([], $result);
    }
}
