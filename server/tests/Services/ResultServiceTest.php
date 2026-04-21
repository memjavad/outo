<?php
namespace Tests\Services;

use PHPUnit\Framework\TestCase;
use App\Services\ResultService;
use App\Repositories\ResultRepository;

class ResultServiceTest extends TestCase {

    public function testSaveResultSuccess() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $mockRepo->method('createResult')->willReturn(123);

        $mockStmt = $this->createMock(\PDOStatement::class);
        $mockStmt->method('execute')->willReturn(true);
        $mockStmt->method('fetch')->willReturn(['exam_type' => 'standard']);

        $mockDb = $this->createMock(\PDO::class);
        $mockDb->method('prepare')->willReturn($mockStmt);

        $mockRepo->method('getDb')->willReturn($mockDb);

        $service = new ResultService($mockRepo);

        $data = [
            'studentName' => 'John Doe',
            'scorePercentage' => 85,
            'grade' => 'B',
            'studentId' => 1,
            'examId' => 1,
            'totalQuestions' => 10,
            'correctAnswers' => 8,
            'timeTakenSeconds' => 120,
            'earned_stars' => 0,
            'campaign_score' => 0
        ];

        $result = $service->saveResult($data);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals(123, $result['id']);
        $this->assertEquals(80 + 25, $result['points_earned']);
    }

    public function testSaveResultEssayOverride() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $mockRepo->method('createResult')->willReturn(124);

        $mockStmt = $this->createMock(\PDOStatement::class);
        $mockStmt->method('execute')->willReturn(true);
        $mockStmt->method('fetch')->willReturn(['exam_type' => 'essay']);

        $mockDb = $this->createMock(\PDO::class);
        $mockDb->method('prepare')->willReturn($mockStmt);

        $mockRepo->method('getDb')->willReturn($mockDb);

        $service = new ResultService($mockRepo);

        $data = [
            'studentName' => 'Jane Doe',
            'scorePercentage' => 90,
            'grade' => 'A',
            'studentId' => 2,
            'examId' => 2,
            'totalQuestions' => 1,
            'correctAnswers' => 1,
            'timeTakenSeconds' => 60,
        ];

        $result = $service->saveResult($data);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals(124, $result['id']);
        $this->assertEquals(0, $result['points_earned']);
    }

    public function testSaveResultCampaignScore() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $mockRepo->method('createResult')->willReturn(125);
        $mockRepo->expects($this->once())->method('awardPoints')->with(3, 500);
        $mockRepo->expects($this->once())->method('awardStars')->with(3, 5);

        $mockStmt = $this->createMock(\PDOStatement::class);
        $mockStmt->method('execute')->willReturn(true);
        $mockStmt->method('fetch')->willReturn(['exam_type' => 'campaign']);

        $mockDb = $this->createMock(\PDO::class);
        $mockDb->method('prepare')->willReturn($mockStmt);

        $mockRepo->method('getDb')->willReturn($mockDb);

        $service = new ResultService($mockRepo);

        $data = [
            'studentName' => 'Campaign User',
            'studentId' => 3,
            'examId' => 3,
            'campaign_score' => 500,
            'earned_stars' => 5,
            'correctAnswers' => 10,
        ];

        $result = $service->saveResult($data);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals(125, $result['id']);
        $this->assertEquals(500, $result['points_earned']);
    }

    public function testSaveResultFlawlessScore() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $mockRepo->method('createResult')->willReturn(126);
        $mockRepo->expects($this->once())->method('awardPoints')->with(4, 100 + 50 + 25);

        $mockStmt = $this->createMock(\PDOStatement::class);
        $mockStmt->method('execute')->willReturn(true);
        $mockStmt->method('fetch')->willReturn(['exam_type' => 'standard']);

        $mockDb = $this->createMock(\PDO::class);
        $mockDb->method('prepare')->willReturn($mockStmt);

        $mockRepo->method('getDb')->willReturn($mockDb);

        $service = new ResultService($mockRepo);

        $data = [
            'studentName' => 'Flawless User',
            'studentId' => 4,
            'examId' => 4,
            'scorePercentage' => 100,
            'totalQuestions' => 10,
            'correctAnswers' => 10,
            'timeTakenSeconds' => 150,
            'earned_stars' => 0,
            'campaign_score' => 0
        ];

        $result = $service->saveResult($data);

        $this->assertEquals(126, $result['id']);
        $this->assertEquals(175, $result['points_earned']);
    }

    public function testSaveResultMinParticipationAward() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $mockRepo->method('createResult')->willReturn(127);
        $mockRepo->expects($this->once())->method('awardPoints')->with(5, 10);

        $mockStmt = $this->createMock(\PDOStatement::class);
        $mockStmt->method('execute')->willReturn(true);
        $mockStmt->method('fetch')->willReturn(['exam_type' => 'standard']);

        $mockDb = $this->createMock(\PDO::class);
        $mockDb->method('prepare')->willReturn($mockStmt);

        $mockRepo->method('getDb')->willReturn($mockDb);

        $service = new ResultService($mockRepo);

        $data = [
            'studentName' => 'Poor User',
            'studentId' => 5,
            'examId' => 5,
            'scorePercentage' => 0,
            'totalQuestions' => 10,
            'correctAnswers' => 0,
            'timeTakenSeconds' => 600,
            'earned_stars' => 0,
            'campaign_score' => 0
        ];

        $result = $service->saveResult($data);

        $this->assertEquals(127, $result['id']);
        $this->assertEquals(10, $result['points_earned']);
    }

    public function testGetStudentResults() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $expectedResults = [['id' => 1, 'score' => 80]];
        $mockRepo->method('getStudentResults')->with(1)->willReturn($expectedResults);

        $service = new ResultService($mockRepo);

        $results = $service->getStudentResults(1);

        $this->assertEquals($expectedResults, $results);
    }

    public function testGradeResult() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $mockRepo->expects($this->once())->method('gradeResult')->with(1, 95.5, 'A+', 'Great job');

        $service = new ResultService($mockRepo);

        $result = $service->gradeResult(1, 95.5, 'A+', 'Great job', 2, 100);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals('Result graded safely.', $result['message']);
    }

    public function testGetLeaderboard() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $expectedLeaderboard = [['student_name' => 'John', 'score' => 90]];
        $mockRepo->method('getLeaderboard')->with(1)->willReturn($expectedLeaderboard);

        $service = new ResultService($mockRepo);

        $result = $service->getLeaderboard(1);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals($expectedLeaderboard, $result['leaderboard']);
    }

    public function testGetCampaignLeaderboard() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $expectedLeaderboard = [['student_name' => 'Campaigner', 'score' => 500]];
        $mockRepo->method('getCampaignLeaderboard')->willReturn($expectedLeaderboard);

        $service = new ResultService($mockRepo);

        $result = $service->getCampaignLeaderboard();

        $this->assertEquals('success', $result['status']);
        $this->assertEquals($expectedLeaderboard, $result['leaderboard']);
    }

    public function testClearResults() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $mockRepo->expects($this->once())->method('clearResults');

        $service = new ResultService($mockRepo);

        $result = $service->clearResults();

        $this->assertEquals('success', $result['status']);
    }
}
