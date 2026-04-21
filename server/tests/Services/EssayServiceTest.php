<?php
namespace Tests\Services;

use PHPUnit\Framework\TestCase;
use App\Services\EssayService;
use App\Repositories\EssayRepository;

class EssayServiceTest extends TestCase {

    private function createMockRepository() {
        return $this->createMock(EssayRepository::class);
    }

    public function testSaveEssayResultWithStandardData() {
        $repoMock = $this->createMockRepository();

        $repoMock->expects($this->once())
                 ->method('createEssayResult')
                 ->with($this->callback(function($resultData) {
                     return $resultData['student_name'] === 'Jane Doe'
                         && $resultData['student_id'] === 123
                         && $resultData['exam_id'] === 456
                         && $resultData['score_percentage'] === 0
                         && $resultData['grade'] === 'Pending Grading'
                         && $resultData['time_taken_seconds'] === 300
                         && $resultData['gps_location'] === '40.7128,-74.0060'
                         && $resultData['cheat_flag'] === 0
                         && $resultData['answers_json'] === json_encode(['Q1' => 'A1'])
                         && $resultData['is_graded'] === 0
                         && isset($resultData['scheduled_grading_time']);
                 }))
                 ->willReturn(999);

        $repoMock->expects($this->once())
                 ->method('isWebhookEnabled')
                 ->willReturn(false);

        $service = new EssayService($repoMock);

        $data = [
            'student_name' => 'Jane Doe',
            'student_id' => 123,
            'exam_id' => 456,
            'time_taken_seconds' => 300,
            'gps_location' => '40.7128,-74.0060',
            'cheat_flag' => 0,
            'answers_json' => ['Q1' => 'A1']
        ];

        $result = $service->saveEssayResult($data);

        $this->assertEquals([
            "status" => "success",
            "id" => 999,
            "points_earned" => 0
        ], $result);
    }

    public function testSaveEssayResultWithAlternativeKeys() {
        $repoMock = $this->createMockRepository();

        $repoMock->expects($this->once())
                 ->method('createEssayResult')
                 ->with($this->callback(function($resultData) {
                     return $resultData['student_name'] === 'John Smith'
                         && $resultData['exam_id'] === 789
                         && $resultData['time_taken_seconds'] === 600
                         && $resultData['gps_location'] === '34.0522,-118.2437'
                         && $resultData['cheat_flag'] === 1
                         && $resultData['answers_json'] === json_encode(['Q2' => 'A2']);
                 }))
                 ->willReturn(888);

        $repoMock->expects($this->once())
                 ->method('isWebhookEnabled')
                 ->willReturn(false);

        $service = new EssayService($repoMock);

        $data = [
            'studentName' => 'John Smith',
            'examId' => 789,
            'timeTakenSeconds' => 600,
            'gpsLocation' => '34.0522,-118.2437',
            'cheatFlag' => 1,
            'answersJson' => ['Q2' => 'A2']
        ];

        $result = $service->saveEssayResult($data);

        $this->assertEquals([
            "status" => "success",
            "id" => 888,
            "points_earned" => 0
        ], $result);
    }

    public function testGradeEssay() {
        $repoMock = $this->createMockRepository();

        $repoMock->expects($this->once())
                 ->method('gradeEssay')
                 ->with(999, 85.5, 'B+', 'Good job!');

        $service = new EssayService($repoMock);

        $result = $service->gradeEssay(999, 85.5, 'B+', 'Good job!', 123, 10);

        $this->assertEquals([
            "status" => "success",
            "message" => "Essay graded successfully."
        ], $result);
    }

    public function testGetPendingEssays() {
        $repoMock = $this->createMockRepository();
        $expectedEssays = [
            ['id' => 1, 'student_name' => 'Alice'],
            ['id' => 2, 'student_name' => 'Bob']
        ];

        $repoMock->expects($this->once())
                 ->method('getPendingEssays')
                 ->willReturn($expectedEssays);

        $service = new EssayService($repoMock);

        $result = $service->getPendingEssays();

        $this->assertEquals($expectedEssays, $result);
    }

    public function testWebhookTriggered() {
        $repoMock = $this->createMockRepository();

        $repoMock->expects($this->once())
                 ->method('createEssayResult')
                 ->willReturn(777);

        $repoMock->expects($this->once())
                 ->method('isWebhookEnabled')
                 ->willReturn(true);

        $repoMock->expects($this->once())
                 ->method('getActiveWebhooks')
                 ->with('essay_submitted')
                 ->willReturn([]); // Return empty array to avoid making actual HTTP requests during test

        $service = new EssayService($repoMock);

        $data = [
            'student_name' => 'Webhook Tester',
            'exam_id' => 111
        ];

        $result = $service->saveEssayResult($data);

        $this->assertEquals([
            "status" => "success",
            "id" => 777,
            "points_earned" => 0
        ], $result);
    }
}
