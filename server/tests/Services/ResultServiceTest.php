<?php
namespace Tests\Services;

use PHPUnit\Framework\TestCase;
use App\Services\ResultService;
use App\Repositories\ResultRepository;
use PDO;
use PDOStatement;

class ResultServiceTest extends TestCase {

    private function createMockRepo() {
        return $this->createMock(ResultRepository::class);
    }

    public function testSaveResultStandardExam() {
        $mockRepo = $this->createMockRepo();
        $mockRepo->expects($this->once())->method('createResult')->willReturn(123);
        $mockRepo->expects($this->once())->method('markSessionCompleted')->with('John');
        $mockRepo->expects($this->once())->method('isWebhookEnabled')->willReturn(false);
        $mockRepo->expects($this->once())->method('awardPoints')->with(1, 125);

        $service = new ResultService($mockRepo);

        $data = [
            'studentName' => 'John',
            'studentId' => 1,
            'correctAnswers' => 5,
            'scorePercentage' => '100%',
            'timeTakenSeconds' => 10,
            'totalQuestions' => 5
        ];

        $result = $service->saveResult($data);

        $this->assertEquals([
            "status" => "success",
            "id" => 123,
            "points_earned" => 125
        ], $result);
    }

    public function testSaveResultEssayExam() {
        $mockRepo = $this->createMockRepo();
        $mockRepo->expects($this->once())->method('createResult')->willReturn(456);

        $mockPdo = $this->createMock(PDO::class);
        $mockStmt = $this->createMock(PDOStatement::class);

        // Simulating the query for ExamRepository->getById(10)
        $mockPdo->expects($this->once())->method('prepare')->willReturn($mockStmt);
        $mockStmt->expects($this->once())->method('execute')->with([10]);
        $mockStmt->expects($this->once())->method('fetch')->willReturn(['id' => 10, 'exam_type' => 'essay']);

        $mockRepo->method('getDb')->willReturn($mockPdo);

        $service = new ResultService($mockRepo);

        $data = [
            'studentName' => 'Alice',
            'examId' => 10
        ];

        $result = $service->saveResult($data);

        $this->assertEquals([
            "status" => "success",
            "id" => 456,
            "points_earned" => 0
        ], $result);
    }

    public function testSaveResultWithStarsAndCampaign() {
        $mockRepo = $this->createMockRepo();
        $mockRepo->expects($this->once())->method('createResult')->willReturn(789);
        $mockRepo->expects($this->once())->method('awardStars')->with(2, 5);
        $mockRepo->expects($this->once())->method('awardPoints')->with(2, 50);

        $service = new ResultService($mockRepo);

        $data = [
            'studentName' => 'Bob',
            'studentId' => 2,
            'earned_stars' => 5,
            'campaign_score' => 50
        ];

        $result = $service->saveResult($data);

        $this->assertEquals([
            "status" => "success",
            "id" => 789,
            "points_earned" => 50
        ], $result);
    }

    public function testGetStudentResults() {
        $mockRepo = $this->createMockRepo();
        $expected = [['id' => 1, 'score_percentage' => 85]];
        $mockRepo->expects($this->once())->method('getStudentResults')->with(1)->willReturn($expected);

        $service = new ResultService($mockRepo);
        $this->assertEquals($expected, $service->getStudentResults(1));
    }

    public function testGradeResult() {
        $mockRepo = $this->createMockRepo();
        $mockRepo->expects($this->once())->method('gradeResult')->with(1, 90.0, 'A', 'Good job');

        $service = new ResultService($mockRepo);
        $result = $service->gradeResult(1, 90.0, 'A', 'Good job', 10, 50);
        $this->assertEquals(["status" => "success", "message" => "Result graded safely."], $result);
    }

    public function testGetLeaderboard() {
        $mockRepo = $this->createMockRepo();
        $expected = [['student_name' => 'Alice', 'score_percentage' => 100]];
        $mockRepo->expects($this->once())->method('getLeaderboard')->with(5)->willReturn($expected);

        $service = new ResultService($mockRepo);
        $this->assertEquals(["status" => "success", "leaderboard" => $expected], $service->getLeaderboard(5));
    }

    public function testGetCampaignLeaderboard() {
        $mockRepo = $this->createMockRepo();
        $expected = [['student_name' => 'Bob', 'score_percentage' => 500]];
        $mockRepo->expects($this->once())->method('getCampaignLeaderboard')->willReturn($expected);

        $service = new ResultService($mockRepo);
        $this->assertEquals(["status" => "success", "leaderboard" => $expected], $service->getCampaignLeaderboard());
    }

    public function testClearResults() {
        $mockRepo = $this->createMockRepo();
        $mockRepo->expects($this->once())->method('clearResults');

        $service = new ResultService($mockRepo);
        $this->assertEquals(["status" => "success"], $service->clearResults());
    }
}
