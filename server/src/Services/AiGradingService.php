<?php
namespace App\Services;

class AiGradingService {
    private string $apiKey;
    private string $model;

    public function __construct(string $apiKey, string $model) {
        $this->apiKey = $apiKey;
        $this->model = $model;
    }

    public function gradeSingleEssay(array $essayData, ?string $rubric, ?string $gradingType, string $feedbackLanguage = 'Arabic'): ?array {
        try {
            $rubric = $rubric ?? 'No rubric provided.';
            $gradingType = $gradingType ?? 'percentage';

            if (empty($this->apiKey)) {
            error_log("AiGradingService: API Key is missing. Cannot grade essay ID {$essayData['id']}");
            return null;
        }

        // Prepare the text to evaluate
        $answersJson = $essayData['answers_json'] ?? '';
        
        $systemInstruction = "You are an expert academic evaluator. Your task is to grade a student's essay exam based on the following RUBRIC.\n\n";
        $systemInstruction .= "RUBRIC:\n$rubric\n\n";
        $systemInstruction .= "The exam uses a '$gradingType' grading system. If 'percentage', the 'grade' field can just be 'A', 'B', 'C', 'D', or 'F' based on the score. If 'arabic', the 'grade' field MUST be mathematically mapped exactly into one of these 5 Arabic strings based on the score percentage:\n";
        $systemInstruction .= "90-100: ممتاز\n80-89: جيد جدا\n70-79: جيد\n50-69: متوسط\n0-49: ضعيف\n\n";
        $systemInstruction .= "You must output your evaluation strictly as a valid minified JSON object with NO markdown formatting, NO backticks, and exactly these three keys:\n";
        $systemInstruction .= '{"score_percentage": (integer 0-100), "grade": (string), "feedback": (detailed string evaluating the essay against the rubric)}' . "\n\n";
        $systemInstruction .= "CRITICAL: You MUST write the 'feedback' text entirely in $feedbackLanguage. Do not use any other language for the feedback. The 'feedback' MUST be extremely concise and MUST NOT exceed 20 words in total.";

        $isGemma = str_starts_with(strtolower($this->model), 'gemma');

        if ($isGemma) {
            // Gemma does not support systemInstruction or JSON MIME types
            $userPayload = $systemInstruction . "\n\nStudent Responses JSON:\n" . $answersJson;
            $postData = [
                "contents" => [
                    [
                        "role" => "user",
                        "parts" => [
                            ["text" => $userPayload]
                        ]
                    ]
                ],
                "generationConfig" => [
                    "temperature" => 0.2
                ]
            ];
        } else {
            // Gemini natively supports Structured JSON Outputs & System Instructions
            $userPayload = "Student Responses JSON:\n" . $answersJson;
            $postData = [
                "systemInstruction" => [
                    "parts" => [
                        ["text" => $systemInstruction]
                    ]
                ],
                "contents" => [
                    [
                        "role" => "user",
                        "parts" => [
                            ["text" => $userPayload]
                        ]
                    ]
                ],
                "generationConfig" => [
                    "temperature" => 0.2,
                    "response_mime_type" => "application/json"
                ]
            ];
        }

        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$this->model}:generateContent?key={$this->apiKey}";

        [$response, $httpCode] = $this->executeRequest($url, $postData);

        if ($httpCode !== 200) {
            $errorDiagnostic = "AiGradingService Error ($httpCode): " . $response . "\nPayload sent: " . json_encode($postData);
            error_log($errorDiagnostic);
            file_put_contents(__DIR__ . '/../../ai_debug.log', date('[Y-m-d H:i:s] ') . $errorDiagnostic . "\n", FILE_APPEND);
            return null;
        }

        $decoded = json_decode($response, true);
        $text = $decoded['candidates'][0]['content']['parts'][0]['text'] ?? '';
        
        // Use RegEx to scrape out the JSON block avoiding conversational text wrappers
        if (preg_match('/\{.*\}/s', $text, $matches)) {
            $text = trim($matches[0]);
        }

        $parsed = json_decode($text, true);
        
        if (json_last_error() === JSON_ERROR_NONE && isset($parsed['score_percentage'])) {
            return [
                'score_percentage' => (int)$parsed['score_percentage'],
                'grade' => $parsed['grade'] ?? 'Calculated',
                'feedback' => $parsed['feedback'] ?? ''
            ];
        } else {
            $errorLogMsg = "AiGradingService JSON parse failure.\nRaw AI Response: " . $text . "\nJSON Error: " . json_last_error_msg();
            error_log($errorLogMsg);
            file_put_contents(__DIR__ . '/../../ai_debug.log', date('[Y-m-d H:i:s] ') . $errorLogMsg . "\n\n", FILE_APPEND);
        }

        return null;
        } catch (\Throwable $e) {
            $crashMsg = "FATAL CRASH in AiGradingService: " . $e->getMessage() . " at line " . $e->getLine();
            error_log($crashMsg);
            file_put_contents(__DIR__ . '/../../ai_debug.log', date('[Y-m-d H:i:s] ') . $crashMsg . "\n", FILE_APPEND);
            return null;
        }
    }

    /**
     * Executes the HTTP request. Extracted for testability.
     * @return array [responseString, httpCode]
     */
    protected function executeRequest(string $url, array $postData): array {
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($postData));
        curl_setopt($ch, CURLOPT_TIMEOUT, 45); // Give AI sufficient time

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        return [$response, $httpCode];
    }
}
