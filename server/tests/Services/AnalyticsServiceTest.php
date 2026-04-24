<?php
namespace Tests\Services;

use PHPUnit\Framework\TestCase;
use App\Services\AnalyticsService;

class AnalyticsServiceTest extends TestCase {
    private \PDO $pdo;
    private AnalyticsService $service;

    protected function setUp(): void {
        $this->pdo = new \PDO('sqlite::memory:');
        $this->pdo->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);

        // Setup test tables based on the actual schema
        $this->pdo->exec("
            CREATE TABLE results (
                id INTEGER PRIMARY KEY,
                exam_id INTEGER,
                score_percentage FLOAT,
                time_taken_seconds INTEGER
            )
        ");

        $this->pdo->exec("
            CREATE TABLE questions (
                id INTEGER PRIMARY KEY,
                exam_id INTEGER,
                question_text TEXT,
                question_type TEXT
            )
        ");

        $this->pdo->exec("
            CREATE TABLE student_responses (
                id INTEGER PRIMARY KEY,
                question_id INTEGER,
                selected_option_index INTEGER
            )
        ");

        // Use reflection to bypass singleton and constructor for testing
        $reflection = new \ReflectionClass(AnalyticsService::class);
        $this->service = $reflection->newInstanceWithoutConstructor();

        $property = $reflection->getProperty('db');
        $property->setAccessible(true);
        $property->setValue($this->service, $this->pdo);
}

    public function testGetExamKPIsWithData() {
        // Insert test data: 2 passing results, 1 failing result for exam 1
        $this->pdo->exec("INSERT INTO results (exam_id, score_percentage, time_taken_seconds) VALUES (1, 80.5, 120)");
        $this->pdo->exec("INSERT INTO results (exam_id, score_percentage, time_taken_seconds) VALUES (1, 40.0, 100)");
        $this->pdo->exec("INSERT INTO results (exam_id, score_percentage, time_taken_seconds) VALUES (1, 90.0, 110)");

        // Different exam to ensure WHERE clause works
        $this->pdo->exec("INSERT INTO results (exam_id, score_percentage, time_taken_seconds) VALUES (2, 90.0, 150)");

        $kpis = $this->service->getExamKPIs(1);

        $this->assertEquals(3, $kpis['total_students']);
        $this->assertEquals(70.17, $kpis['average_score']); // (80.5 + 40.0 + 90.0) / 3
        $this->assertEquals(110, $kpis['average_time_seconds']); // (120 + 100 + 110) / 3
        $this->assertEquals(66.67, $kpis['pass_rate']); // 2 / 3 >= 50
    }

    public function testGetExamKPIsEmpty() {
        $kpis = $this->service->getExamKPIs(999);

        $this->assertEquals(0, $kpis['total_students']);
        $this->assertEquals(0, $kpis['average_score']);
        $this->assertEquals(0, $kpis['average_time_seconds']);
        $this->assertEquals(0, $kpis['pass_rate']);
    }

    public function testGetDistractorAnalysis() {
        // Setup data for exam 1, question 10
        $this->pdo->exec("INSERT INTO questions (id, exam_id, question_text, question_type) VALUES (10, 1, 'Q1', 'single')");

        // Responses for question 10
        // Opt 0: 1 time
        // Opt 1: 2 times
        // Opt null: 1 time (mapped to -1)
        $this->pdo->exec("INSERT INTO student_responses (question_id, selected_option_index) VALUES (10, 0)");
        $this->pdo->exec("INSERT INTO student_responses (question_id, selected_option_index) VALUES (10, 1)");
        $this->pdo->exec("INSERT INTO student_responses (question_id, selected_option_index) VALUES (10, 1)");
        $this->pdo->exec("INSERT INTO student_responses (question_id, selected_option_index) VALUES (10, NULL)");

        $analysis = $this->service->getDistractorAnalysis(1);

        $this->assertCount(1, $analysis);
        $qData = $analysis[0];

        $this->assertEquals(10, $qData['question_id']);
        $this->assertEquals('Q1', $qData['question_text']);
        $this->assertEquals(4, $qData['total_answers']);

        // Check distractors distribution
        $distractors = $qData['distractors'];

        $opt0 = array_filter($distractors, fn($d) => $d['option_index'] === 0);
        $opt1 = array_filter($distractors, fn($d) => $d['option_index'] === 1);
        $optNull = array_filter($distractors, fn($d) => $d['option_index'] === -1);

        $this->assertCount(1, $opt0);
        $this->assertCount(1, $opt1);
        $this->assertCount(1, $optNull);

        $this->assertEquals(25.0, current($opt0)['percentage']);
        $this->assertEquals(50.0, current($opt1)['percentage']);
        $this->assertEquals(25.0, current($optNull)['percentage']);
    }

    public function testGetDistractorAnalysisExcludesEssay() {
        $this->pdo->exec("INSERT INTO questions (id, exam_id, question_text, question_type) VALUES (20, 1, 'Essay Q', 'essay')");
        $this->pdo->exec("INSERT INTO student_responses (question_id, selected_option_index) VALUES (20, NULL)");

        $analysis = $this->service->getDistractorAnalysis(1);
        $this->assertCount(0, $analysis);
    }
}
