<?php
namespace Tests\Services;

use PHPUnit\Framework\TestCase;
use App\Services\ResultService;
use App\Repositories\ResultRepository;

class ResultServiceTest extends TestCase {

    public function testGetStudentResults() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $mockRepo->method('getStudentResults')
                 ->with($this->equalTo(1))
                 ->willReturn(['result1', 'result2']);

        $service = new ResultService($mockRepo);
        $result = $service->getStudentResults(1);

        $this->assertEquals(['result1', 'result2'], $result);
    }

    public function testGradeResult() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $mockRepo->expects($this->once())
                 ->method('gradeResult')
                 ->with($this->equalTo(10), $this->equalTo(95.5), $this->equalTo('A'), $this->equalTo('Good job!'));

        $service = new ResultService($mockRepo);
        $result = $service->gradeResult(10, 95.5, 'A', 'Good job!', 1, 50);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals('Result graded safely.', $result['message']);
    }

    public function testGetLeaderboard() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $mockRepo->method('getLeaderboard')
                 ->with($this->equalTo(5))
                 ->willReturn([['student_name' => 'Alice', 'score' => 100]]);

        $service = new ResultService($mockRepo);
        $result = $service->getLeaderboard(5);

        $this->assertEquals('success', $result['status']);
        $this->assertCount(1, $result['leaderboard']);
        $this->assertEquals('Alice', $result['leaderboard'][0]['student_name']);
    }

    public function testGetCampaignLeaderboard() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $mockRepo->method('getCampaignLeaderboard')
                 ->willReturn([['student_name' => 'Bob', 'score' => 200]]);

        $service = new ResultService($mockRepo);
        $result = $service->getCampaignLeaderboard();

        $this->assertEquals('success', $result['status']);
        $this->assertCount(1, $result['leaderboard']);
        $this->assertEquals('Bob', $result['leaderboard'][0]['student_name']);
    }

    public function testClearResults() {
        $mockRepo = $this->createMock(ResultRepository::class);
        $mockRepo->expects($this->once())
                 ->method('clearResults');

        $service = new ResultService($mockRepo);
        $result = $service->clearResults();

        $this->assertEquals('success', $result['status']);
    }

    public function testSaveResultStandardExam() {
        $mockRepo = $this->createMock(ResultRepository::class);

        // Mock Db for ExamRepository inside saveResult
        $mockDb = $this->createMock(\PDO::class);
        $mockStmt = $this->createMock(\PDOStatement::class);
        $mockStmt->method('execute')->willReturn(true);
        $mockStmt->method('fetch')->willReturn(['exam_type' => 'standard']);
        $mockDb->method('prepare')->willReturn($mockStmt);
        $mockRepo->method('getDb')->willReturn($mockDb);

        // Assert expectations
        $mockRepo->expects($this->once())
                 ->method('createResult')
                 ->willReturn(123);

        $mockRepo->expects($this->once())
                 ->method('markSessionCompleted')
                 ->with($this->equalTo('John Doe'));

        $mockRepo->expects($this->once())
                 ->method('awardPoints');

        $mockRepo->expects($this->once())
                 ->method('awardStars')
                 ->with($this->equalTo(5), $this->equalTo(3));

        $mockRepo->method('isWebhookEnabled')->willReturn(false);

        $service = new ResultService($mockRepo);
        $data = [
            'studentName' => 'John Doe',
            'studentId' => 5,
            'examId' => 10,
            'scorePercentage' => 85,
            'grade' => 'B',
            'totalQuestions' => 10,
            'correctAnswers' => 8,
            'timeTakenSeconds' => 120,
            'earned_stars' => 3
        ];

        $result = $service->saveResult($data);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals(123, $result['id']);
        // Points calculation: 8 correct * 10 = 80 + 25 (speed bonus) = 105
        $this->assertEquals(105, $result['points_earned']);
    }

    public function testSaveResultEssayExam() {
        $mockRepo = $this->createMock(ResultRepository::class);

        // Mock Db for ExamRepository inside saveResult
        $mockDb = $this->createMock(\PDO::class);
        $mockStmt = $this->createMock(\PDOStatement::class);
        $mockStmt->method('execute')->willReturn(true);
        $mockStmt->method('fetch')->willReturn(['exam_type' => 'essay']);
        $mockDb->method('prepare')->willReturn($mockStmt);
        $mockRepo->method('getDb')->willReturn($mockDb);

        // Verify createResult receives overridden data
        $mockRepo->expects($this->once())
                 ->method('createResult')
                 ->with($this->callback(function($arg) {
                     return $arg['is_graded'] === 0 &&
                            $arg['score_percentage'] === 0 &&
                            $arg['grade'] === 'Pending Grading';
                 }))
                 ->willReturn(124);

        $mockRepo->expects($this->never())
                 ->method('awardPoints'); // Points awarded later for essay exams

        $mockRepo->method('isWebhookEnabled')->willReturn(false);

        $service = new ResultService($mockRepo);
        $data = [
            'studentName' => 'Jane Doe',
            'studentId' => 6,
            'examId' => 11,
            // These should be overridden
            'scorePercentage' => 100,
            'grade' => 'A'
        ];

        $result = $service->saveResult($data);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals(0, $result['points_earned']);
    }

    public function testSaveResultCampaignScore() {
        $mockRepo = $this->createMock(ResultRepository::class);

        // Mock Db for ExamRepository inside saveResult
        $mockDb = $this->createMock(\PDO::class);
        $mockStmt = $this->createMock(\PDOStatement::class);
        $mockStmt->method('execute')->willReturn(true);
        $mockStmt->method('fetch')->willReturn(['exam_type' => 'campaign']);
        $mockDb->method('prepare')->willReturn($mockStmt);
        $mockRepo->method('getDb')->willReturn($mockDb);

        // Assert expectations
        $mockRepo->expects($this->once())
                 ->method('createResult')
                 ->willReturn(125);

        $mockRepo->expects($this->once())
                 ->method('markSessionCompleted')
                 ->with($this->equalTo('Jack Doe'));

        $mockRepo->expects($this->once())
                 ->method('awardPoints')
                 ->with($this->equalTo(7), $this->equalTo(500));

        $mockRepo->method('isWebhookEnabled')->willReturn(false);

        $service = new ResultService($mockRepo);
        $data = [
            'studentName' => 'Jack Doe',
            'studentId' => 7,
            'examId' => 12,
            'campaign_score' => 500
        ];

        $result = $service->saveResult($data);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals(125, $result['id']);
        $this->assertEquals(500, $result['points_earned']);
    }

    public function testSaveResultWebhookTriggered() {
        $mockRepo = $this->createMock(ResultRepository::class);

        // Mock Db for ExamRepository inside saveResult
        $mockDb = $this->createMock(\PDO::class);
        $mockStmt = $this->createMock(\PDOStatement::class);
        $mockStmt->method('execute')->willReturn(true);
        $mockStmt->method('fetch')->willReturn(null);
        $mockDb->method('prepare')->willReturn($mockStmt);
        $mockRepo->method('getDb')->willReturn($mockDb);

        $mockRepo->method('isWebhookEnabled')->willReturn(true);
        $mockRepo->expects($this->once())
                 ->method('getActiveWebhooks')
                 ->with('result_submitted')
                 ->willReturn([['url' => 'http://localhost/test-webhook']]);

        // We can't easily mock curl, but we can verify getActiveWebhooks was called

        $service = new ResultService($mockRepo);
        $data = [
            'studentName' => 'Webhook User'
        ];

        $result = $service->saveResult($data);

        $this->assertEquals('success', $result['status']);
    }
}
