<?php
namespace App\Services;

use App\Repositories\StudentRepository;

class StudentService {
    private StudentRepository $studentRepo;

    public function __construct(StudentRepository $studentRepo) {
        $this->studentRepo = $studentRepo;
    }

    public function registerStudent(array $validatedData): array {
        $name = $validatedData['name'];
        $phone = $validatedData['phone'];
        $passwordHash = password_hash($validatedData['password'], PASSWORD_DEFAULT);

        $studentId = $this->studentRepo->create([
            'name' => $name,
            'phone' => $phone,
            'password_hash' => $passwordHash,
            'enrolled' => 0
        ]);
        
        $token = $this->generateToken($studentId);
        
        return [
            "status" => "success",
            "token" => $token,
            "student" => [
                "id" => $studentId,
                "name" => $name,
                "phone" => $phone,
                "points" => 0,
                "total_xp" => 0
            ]
        ];
    }

    public function loginStudent(array $validatedData) {
        $student = $this->studentRepo->findByPhone($validatedData['phone']);

        if ($student && $student['enrolled'] == 1 && password_verify($validatedData['password'], $student['password_hash'])) {
            $token = $this->generateToken($student['id']);
            unset($student['password_hash']);
            return [
                "status" => "success",
                "token" => $token,
                "student" => $student
            ];
        }

        throw new \Exception("Invalid credentials or not enrolled.");
    }

    public function addStudent(array $validatedData): array {
        $name = $validatedData['name'];
        $phone = $validatedData['phone'];
        $passwordHash = password_hash($validatedData['password'], PASSWORD_DEFAULT);

        try {
            $studentId = $this->studentRepo->create([
                'name' => $name,
                'phone' => $phone,
                'password_hash' => $passwordHash,
                'enrolled' => 1
            ]);
            
            return [
                "status" => "success", 
                "id" => $studentId,
                "name" => $name,
                "phone" => $phone
            ];
        } catch (\PDOException $e) {
            if (strpos($e->getMessage(), 'Duplicate entry') !== false) {
                 throw new \Exception("A student with this Phone Number already exists.", 400);
            }
            throw new \Exception("Failed to add student: " . $e->getMessage(), 500);
        }
    }

    public function bulkImport(array $students): array {
        $imported = 0;
        $errors = [];
        
        foreach ($students as $idx => $s) {
            if (!isset($s['name']) || !isset($s['access_code'])) {
                $errors[] = "Row $idx: missing name or access code";
                continue;
            }
            try {
                $this->studentRepo->importStudent($s['name'], $s['access_code']);
                $imported++;
            } catch (\Exception $e) {
                $errors[] = "Row $idx: " . $e->getMessage();
            }
        }
        
        return [
            "status" => "success", 
            "imported" => $imported, 
            "errors" => $errors
        ];
    }

    private function generateToken(int $studentId): string {
        $token = bin2hex(random_bytes(32));
        $expires = date('Y-m-d H:i:s', strtotime('+30 days'));
        $this->studentRepo->createToken($studentId, $token, $expires);
        return $token;
    }
}
