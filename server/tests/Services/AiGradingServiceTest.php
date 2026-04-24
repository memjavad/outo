<?php

namespace App\Services {
    // Mock curl functions and error_log in the App\Services namespace where they are called
    $mockCurlOptions = [];
    $mockCurlResponse = null;
    $mockCurlHttpCode = 200;
    $mockCurlThrowException = false;
    $mockErrorLog = [];

    function curl_init($url = null) {
        global $mockCurlOptions, $mockCurlThrowException;
        if ($mockCurlThrowException) {
            throw new \Exception("Simulated exception in curl_init");
        }
        $mockCurlOptions['url'] = $url;
        // Return an empty object to simulate a CurlHandle
        return new \stdClass();
    }

    function curl_setopt($ch, $option, $value) {
        global $mockCurlOptions;
        $mockCurlOptions[$option] = $value;
        return true;
    }

    function curl_exec($ch) {
        global $mockCurlResponse;
        return $mockCurlResponse;
    }

    function curl_getinfo($ch, $info) {
        global $mockCurlHttpCode;
        if ($info === CURLINFO_HTTP_CODE) {
            return $mockCurlHttpCode;
        }
        return null;
    }

    function curl_close($ch) {
        // Mock close
    }

    function error_log($message) {
        global $mockErrorLog;
        $mockErrorLog[] = $message;
    }

    // Include the actual service code here so it gets defined in this namespace with mocked functions
    require_once __DIR__ . '/../../src/Services/AiGradingService.php';
}

namespace Tests\Services {
    use PHPUnit\Framework\TestCase;
    use App\Services\AiGradingService;

    /**
     * @runTestsInSeparateProcesses
     * @preserveGlobalState disabled
     */
    class AiGradingServiceTest extends TestCase {
        protected function setUp(): void {
            global $mockCurlOptions, $mockCurlResponse, $mockCurlHttpCode, $mockCurlThrowException, $mockErrorLog;
            $mockCurlOptions = [];
            $mockCurlResponse = null;
            $mockCurlHttpCode = 200;
            $mockCurlThrowException = false;
            $mockErrorLog = [];
        }

        public function testServiceSuccessfullyGradesEssay() {
            global $mockCurlResponse, $mockCurlHttpCode;
            $mockCurlHttpCode = 200;
            $mockCurlResponse = json_encode([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                ['text' => '{"score_percentage": 85, "grade": "B", "feedback": "Good work"}']
                            ]
                        ]
                    ]
                ]
            ]);

            $service = new AiGradingService('fake-api-key', 'gemini-1.5-flash');
            $essayData = ['id' => 123, 'answers_json' => '{"q1": "test answer"}'];

            $result = $service->gradeSingleEssay($essayData, 'Test Rubric', 'percentage');

            $this->assertIsArray($result);
            $this->assertEquals(85, $result['score_percentage']);
            $this->assertEquals('B', $result['grade']);
            $this->assertEquals('Good work', $result['feedback']);
        }

        public function testServiceReturnsNullOnMissingApiKey() {
            global $mockErrorLog;
            $service = new AiGradingService('', 'gemini-1.5-flash');
            $essayData = ['id' => 123, 'answers_json' => '{"q1": "test answer"}'];

            $result = $service->gradeSingleEssay($essayData, 'Test Rubric', 'percentage');

            $this->assertNull($result);
            $this->assertStringContainsString('API Key is missing', $mockErrorLog[0] ?? '');
        }

        public function testServiceReturnsNullOnInvalidHttpStatusCode() {
            global $mockCurlHttpCode, $mockCurlResponse, $mockErrorLog;
            $mockCurlHttpCode = 500;
            $mockCurlResponse = 'Internal Server Error';

            $service = new AiGradingService('fake-api-key', 'gemini-1.5-flash');
            $essayData = ['id' => 123, 'answers_json' => '{"q1": "test answer"}'];

            $result = $service->gradeSingleEssay($essayData, 'Test Rubric', 'percentage');

            $this->assertNull($result);
            $this->assertStringContainsString('AiGradingService Error (500)', $mockErrorLog[0] ?? '');
        }

        public function testServiceReturnsNullOnMalformedJsonResponse() {
            global $mockCurlHttpCode, $mockCurlResponse, $mockErrorLog;
            $mockCurlHttpCode = 200;
            // Provide a response that has valid outer JSON but the text part is invalid JSON
            $mockCurlResponse = json_encode([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                ['text' => 'Not a valid JSON object']
                            ]
                        ]
                    ]
                ]
            ]);

            $service = new AiGradingService('fake-api-key', 'gemini-1.5-flash');
            $essayData = ['id' => 123, 'answers_json' => '{"q1": "test answer"}'];

            $result = $service->gradeSingleEssay($essayData, 'Test Rubric', 'percentage');

            $this->assertNull($result);
            $this->assertStringContainsString('JSON parse failure', $mockErrorLog[0] ?? '');
        }

        public function testServiceReturnsNullOnException() {
            global $mockCurlThrowException, $mockErrorLog;
            $mockCurlThrowException = true; // This will trigger an exception in our mock curl_init

            $service = new AiGradingService('fake-api-key', 'gemini-1.5-flash');
            $essayData = ['id' => 123, 'answers_json' => '{"q1": "test answer"}'];

            $result = $service->gradeSingleEssay($essayData, 'Test Rubric', 'percentage');

            $this->assertNull($result);
            $this->assertStringContainsString('FATAL CRASH in AiGradingService', $mockErrorLog[0] ?? '');
        }
    }
}
