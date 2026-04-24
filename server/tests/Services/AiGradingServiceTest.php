<?php
namespace Tests\Services;

use PHPUnit\Framework\TestCase;
use App\Services\AiGradingService;

// A subclass to mock the HTTP execution
class TestableAiGradingService extends AiGradingService {
    public array $mockResponse = ['', 200];
    public ?string $lastUrl = null;
    public ?array $lastPostData = null;

    protected function executeRequest(string $url, array $postData): array {
        $this->lastUrl = $url;
        $this->lastPostData = $postData;
        return $this->mockResponse;
    }
}

class AiGradingServiceTest extends TestCase {

    protected function tearDown(): void {
        // Clean up ai_debug.log if it was created during testing
        $logFile = __DIR__ . '/../../ai_debug.log';
        if (file_exists($logFile)) {
            unlink($logFile);
        }
        parent::tearDown();
    }

    public function testReturnsNullWhenApiKeyIsEmpty() {
        $service = new TestableAiGradingService('', 'gemini-pro');
        $result = $service->gradeSingleEssay(['id' => 1, 'answers_json' => '{}'], 'rubric', 'percentage');

        $this->assertNull($result);
        $this->assertNull($service->lastUrl); // Execution should not happen
    }

    public function testSuccessfulGradingWithGemini() {
        $service = new TestableAiGradingService('fake-api-key', 'gemini-1.5-pro');

        // Mock successful Gemini response
        $mockJson = json_encode([
            'candidates' => [
                [
                    'content' => [
                        'parts' => [
                            ['text' => '```json\n{"score_percentage": 85, "grade": "B", "feedback": "Good job."}\n```']
                        ]
                    ]
                ]
            ]
        ]);
        $service->mockResponse = [$mockJson, 200];

        $result = $service->gradeSingleEssay(['id' => 1, 'answers_json' => '{"q1": "a1"}'], 'rubric', 'percentage');

        $this->assertNotNull($result);
        $this->assertEquals(85, $result['score_percentage']);
        $this->assertEquals('B', $result['grade']);
        $this->assertEquals('Good job.', $result['feedback']);

        // Assert the payload structure used Gemini's systemInstruction
        $this->assertArrayHasKey('systemInstruction', $service->lastPostData);
        $this->assertStringContainsString('fake-api-key', $service->lastUrl);
    }

    public function testSuccessfulGradingWithGemma() {
        $service = new TestableAiGradingService('fake-api-key', 'gemma-2b');

        // Mock successful Gemma response
        $mockJson = json_encode([
            'candidates' => [
                [
                    'content' => [
                        'parts' => [
                            ['text' => '{"score_percentage": 90, "grade": "A", "feedback": "Excellent."}']
                        ]
                    ]
                ]
            ]
        ]);
        $service->mockResponse = [$mockJson, 200];

        $result = $service->gradeSingleEssay(['id' => 1, 'answers_json' => '{"q1": "a1"}'], 'rubric', 'percentage');

        $this->assertNotNull($result);
        $this->assertEquals(90, $result['score_percentage']);
        $this->assertEquals('A', $result['grade']);
        $this->assertEquals('Excellent.', $result['feedback']);

        // Assert the payload structure does NOT use systemInstruction for Gemma
        $this->assertArrayNotHasKey('systemInstruction', $service->lastPostData);
        // Assert the system instructions are bundled in the user role contents
        $this->assertStringContainsString('RUBRIC:', $service->lastPostData['contents'][0]['parts'][0]['text']);
    }

    public function testReturnsNullOnHttpError() {
        $service = new TestableAiGradingService('fake-api-key', 'gemini-pro');
        $service->mockResponse = ['Internal Server Error', 500];

        $result = $service->gradeSingleEssay(['id' => 1, 'answers_json' => '{}'], 'rubric', 'percentage');

        $this->assertNull($result);
        $this->assertFileExists(__DIR__ . '/../../ai_debug.log');
    }

    public function testReturnsNullOnInvalidJson() {
        $service = new TestableAiGradingService('fake-api-key', 'gemini-pro');
        // Mock response with text that can't be parsed into JSON with required keys
        $mockJson = json_encode([
            'candidates' => [
                [
                    'content' => [
                        'parts' => [
                            ['text' => 'This is not JSON at all']
                        ]
                    ]
                ]
            ]
        ]);
        $service->mockResponse = [$mockJson, 200];

        $result = $service->gradeSingleEssay(['id' => 1, 'answers_json' => '{}'], 'rubric', 'percentage');

        $this->assertNull($result);
        $this->assertFileExists(__DIR__ . '/../../ai_debug.log');
        $logContents = file_get_contents(__DIR__ . '/../../ai_debug.log');
        $this->assertStringContainsString('JSON parse failure', $logContents);
    }
}
