<?php
namespace Tests\Repositories;

use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\Attributes\AllowMockObjectsWithoutExpectations;
use App\Repositories\ResultRepository;
use PDO;
use PDOStatement;

#[AllowMockObjectsWithoutExpectations]
class ResultRepositoryTest extends TestCase {
    private PDO $dbMock;
    private PDOStatement $stmtMock;
    private ResultRepository $repository;

    protected function setUp(): void {
        $this->dbMock = $this->createMock(PDO::class);
        $this->stmtMock = $this->createMock(PDOStatement::class);
        $this->repository = new ResultRepository($this->dbMock);
    }

    public function testCreateResultWithoutAnswersJson() {
        $data = [
            'student_name' => 'John Doe',
            'student_id' => 1,
            'exam_id' => 10,
            'score_percentage' => 90.5,
            'grade' => 'A',
            'total_questions' => 10,
            'correct_answers' => 9,
            'time_taken_seconds' => 300,
            'gps_location' => '12.34,56.78',
            'cheat_flag' => 0,
            'answers_json' => '',
            'is_graded' => 1,
            'earned_stars' => 3,
            'campaign_score' => 100
        ];

        $this->dbMock->expects($this->once())
            ->method('prepare')
            ->with("INSERT INTO results (student_name, student_id, exam_id, score_percentage, grade, total_questions, correct_answers, time_taken_seconds, gps_location, cheat_flag, answers_json, is_graded, earned_stars, campaign_score) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with([
                'John Doe', 1, 10, 90.5, 'A', 10, 9, 300, '12.34,56.78', 0, '', 1, 3, 100
            ]);

        $this->dbMock->expects($this->once())
            ->method('lastInsertId')
            ->willReturn('42');

        $resultId = $this->repository->createResult($data);
        $this->assertEquals(42, $resultId);
    }

    public function testCreateResultWithAnswersJson() {
        $data = [
            'student_name' => 'Jane Doe',
            'student_id' => 2,
            'exam_id' => 11,
            'score_percentage' => 80.0,
            'grade' => 'B',
            'total_questions' => 5,
            'correct_answers' => 4,
            'time_taken_seconds' => 150,
            'gps_location' => null,
            'cheat_flag' => 0,
            'answers_json' => '{"1": 2, "2": 0}',
            'is_graded' => 1,
            'earned_stars' => 2,
            'campaign_score' => 50
        ];

        $stmtMockResp = $this->createMock(PDOStatement::class);

        $this->dbMock->expects($this->exactly(2))
            ->method('prepare')
            ->willReturnMap([
                ["INSERT INTO results (student_name, student_id, exam_id, score_percentage, grade, total_questions, correct_answers, time_taken_seconds, gps_location, cheat_flag, answers_json, is_graded, earned_stars, campaign_score) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [], $this->stmtMock],
                ["INSERT INTO student_responses (result_id, exam_id, question_id, selected_option_index) VALUES (?, ?, ?, ?)", [], $stmtMockResp]
            ]);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with([
                'Jane Doe', 2, 11, 80.0, 'B', 5, 4, 150, null, 0, '{"1": 2, "2": 0}', 1, 2, 50
            ]);

        $stmtMockResp->expects($this->exactly(2))
            ->method('execute')
            ->with($this->logicalOr(
                $this->equalTo([43, 11, 1, 2]),
                $this->equalTo([43, 11, 2, 0])
            ));

        $this->dbMock->expects($this->once())
            ->method('lastInsertId')
            ->willReturn('43');

        $resultId = $this->repository->createResult($data);
        $this->assertEquals(43, $resultId);
    }

    public function testGradeResult() {
        $this->dbMock->expects($this->once())
            ->method('prepare')
            ->with("UPDATE results SET score_percentage = ?, grade = ?, teacher_feedback = ?, is_graded = 1 WHERE id = ?")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with([85.5, 'B', 'Good job', 123]);

        $this->repository->gradeResult(123, 85.5, 'B', 'Good job');
    }

    public function testGetDb() {
        $this->assertSame($this->dbMock, $this->repository->getDb());
    }

    public function testMarkSessionCompleted() {
        $this->dbMock->expects($this->once())
            ->method('prepare')
            ->with("UPDATE active_sessions SET status = 'completed' WHERE student_name = ? AND status = 'active'")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with(['Alice']);

        $this->repository->markSessionCompleted('Alice');
    }

    public function testAwardPoints() {
        $this->dbMock->expects($this->once())
            ->method('prepare')
            ->with("UPDATE students SET points = COALESCE(points, 0) + ?, total_xp = COALESCE(total_xp, 0) + ? WHERE id = ?")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with([50, 50, 5]);

        $this->repository->awardPoints(5, 50);
    }

    public function testAwardStarsPositive() {
        $this->dbMock->expects($this->once())
            ->method('prepare')
            ->with("UPDATE students SET stars = COALESCE(stars, 0) + ? WHERE id = ?")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with([3, 5]);

        $this->repository->awardStars(5, 3);
    }

    public function testAwardStarsZeroOrNegative() {
        $this->dbMock->expects($this->never())
            ->method('prepare');

        $this->repository->awardStars(5, 0);
        $this->repository->awardStars(5, -2);
    }

    public function testInsertLedger() {
        $this->dbMock->expects($this->once())
            ->method('prepare')
            ->with("INSERT INTO points_ledger (student_name, amount, reason) VALUES (?, ?, ?)")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with(['Bob', 10, 'Bonus']);

        $this->repository->insertLedger('Bob', 10, 'Bonus');
    }

    public function testGetStudentResults() {
        $this->dbMock->expects($this->once())
            ->method('prepare')
            ->with($this->callback(function($query) {
                return is_string($query) && strpos($query, "SELECT r.id, r.exam_id, r.score_percentage") !== false;
            }))
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with([7, 7]);

        $expectedResults = [
            ['id' => 1, 'exam_id' => 10, 'score_percentage' => 90],
            ['id' => 2, 'exam_id' => 11, 'score_percentage' => 85]
        ];

        $this->stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn($expectedResults);

        $results = $this->repository->getStudentResults(7);
        $this->assertEquals($expectedResults, $results);
    }

    public function testGetLeaderboard() {
        $this->dbMock->expects($this->once())
            ->method('prepare')
            ->with($this->callback(function($query) {
                return is_string($query) && strpos($query, "SELECT student_name, MAX(score_percentage) as score_percentage, MIN(time_taken_seconds) as time_taken_seconds") !== false;
            }))
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with([10]);

        $expectedLeaderboard = [
            ['student_name' => 'Alice', 'score_percentage' => 100, 'time_taken_seconds' => 60],
            ['student_name' => 'Bob', 'score_percentage' => 90, 'time_taken_seconds' => 70]
        ];

        $this->stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn($expectedLeaderboard);

        $leaderboard = $this->repository->getLeaderboard(10);
        $this->assertEquals($expectedLeaderboard, $leaderboard);
    }

    public function testGetCampaignLeaderboard() {
        $this->dbMock->expects($this->once())
            ->method('query')
            ->with($this->callback(function($query) {
                return is_string($query) && strpos($query, "SELECT name as student_name, COALESCE(total_xp, 0) as score_percentage") !== false;
            }))
            ->willReturn($this->stmtMock);

        $expectedLeaderboard = [
            ['student_name' => 'Charlie', 'score_percentage' => 500, 'time_taken_seconds' => 0]
        ];

        $this->stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn($expectedLeaderboard);

        $leaderboard = $this->repository->getCampaignLeaderboard();
        $this->assertEquals($expectedLeaderboard, $leaderboard);
    }

    public function testClearResults() {
        $this->dbMock->expects($this->exactly(2))
            ->method('exec')
            ->with($this->logicalOr(
                $this->equalTo("DELETE FROM results"),
                $this->equalTo("DELETE FROM essay_results")
            ));

        $this->repository->clearResults();
    }

    public function testIsWebhookEnabled() {
        $this->dbMock->expects($this->once())
            ->method('query')
            ->with("SELECT setting_value FROM settings WHERE setting_key = 'webhook_enabled'")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('fetchColumn')
            ->willReturn('1');

        $this->assertTrue($this->repository->isWebhookEnabled());
    }

    public function testIsWebhookDisabled() {
        $this->dbMock->expects($this->once())
            ->method('query')
            ->with("SELECT setting_value FROM settings WHERE setting_key = 'webhook_enabled'")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('fetchColumn')
            ->willReturn('0');

        $this->assertFalse($this->repository->isWebhookEnabled());
    }

    public function testGetActiveWebhooks() {
        $this->dbMock->expects($this->once())
            ->method('prepare')
            ->with("SELECT url FROM webhooks WHERE event_name = ? AND is_active = 1")
            ->willReturn($this->stmtMock);

        $this->stmtMock->expects($this->once())
            ->method('execute')
            ->with(['exam_completed']);

        $expectedWebhooks = [
            ['url' => 'https://example.com/webhook1'],
            ['url' => 'https://example.com/webhook2']
        ];

        $this->stmtMock->expects($this->once())
            ->method('fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->willReturn($expectedWebhooks);

        $webhooks = $this->repository->getActiveWebhooks('exam_completed');
        $this->assertEquals($expectedWebhooks, $webhooks);
    }
}
