<?php
namespace App\Services;

use App\Repositories\SessionRepository;

class SessionService {
    private SessionRepository $sessionRepo;

    public function __construct(SessionRepository $sessionRepo) {
        $this->sessionRepo = $sessionRepo;
    }

    public function startSession(array $validatedData, string $ipAddress): array {
        $studentName = $validatedData['studentName'];
        $examId = (int)($validatedData['examId'] ?? 0);
        $totalQuestions = (int)($validatedData['totalQuestions'] ?? 0);

        $this->sessionRepo->createSession($studentName, $examId, $totalQuestions, $ipAddress);
        return ["status" => "success"];
    }

    public function processHeartbeat(array $validatedData): array {
        $studentName = $validatedData['studentName'];
        $currentQuestion = (int)($validatedData['currentQuestion'] ?? 0);
        $answeredCount = (int)($validatedData['answeredCount'] ?? 0);

        $this->sessionRepo->updateHeartbeat($studentName, $currentQuestion, $answeredCount);
        return ["status" => "success"];
    }

    public function listActiveSessions(): array {
        $this->sessionRepo->cleanStaleSessions();
        return $this->sessionRepo->getActiveSessions();
    }
}
