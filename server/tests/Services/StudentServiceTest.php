<?php
namespace Tests\Services;

use PHPUnit\Framework\TestCase;
use App\Services\StudentService;
use App\Repositories\StudentRepository;

class StudentServiceTest extends TestCase {
    private $studentRepoMock;
    private $studentService;

    protected function setUp(): void {
        $this->studentRepoMock = $this->createMock(StudentRepository::class);
        $this->studentService = new StudentService($this->studentRepoMock);
    }

    public function testRegisterStudentSuccess() {
        $data = [
            'name' => 'John Doe',
            'phone' => '1234567890',
            'password' => 'secret123'
        ];

        $this->studentRepoMock->expects($this->once())
            ->method('create')
            ->willReturn(1);

        $this->studentRepoMock->expects($this->once())
            ->method('createToken')
            ->willReturn(true);

        $result = $this->studentService->registerStudent($data);

        $this->assertEquals('success', $result['status']);
        $this->assertArrayHasKey('token', $result);
        $this->assertEquals(1, $result['student']['id']);
        $this->assertEquals('John Doe', $result['student']['name']);
    }

    public function testLoginStudentSuccess() {
        $data = [
            'phone' => '1234567890',
            'password' => 'secret123'
        ];

        $student = [
            'id' => 1,
            'name' => 'John Doe',
            'phone' => '1234567890',
            'enrolled' => 1,
            'password_hash' => password_hash('secret123', PASSWORD_DEFAULT)
        ];

        $this->studentRepoMock->expects($this->once())
            ->method('findByPhone')
            ->with('1234567890')
            ->willReturn($student);

        $this->studentRepoMock->expects($this->once())
            ->method('createToken')
            ->willReturn(true);

        $result = $this->studentService->loginStudent($data);

        $this->assertEquals('success', $result['status']);
        $this->assertArrayHasKey('token', $result);
        $this->assertEquals('John Doe', $result['student']['name']);
        $this->assertArrayNotHasKey('password_hash', $result['student']);
    }

    public function testLoginStudentInvalidCredentials() {
        $data = [
            'phone' => '1234567890',
            'password' => 'wrongpassword'
        ];

        $student = [
            'id' => 1,
            'name' => 'John Doe',
            'phone' => '1234567890',
            'enrolled' => 1,
            'password_hash' => password_hash('secret123', PASSWORD_DEFAULT)
        ];

        $this->studentRepoMock->expects($this->once())
            ->method('findByPhone')
            ->with('1234567890')
            ->willReturn($student);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Invalid credentials or not enrolled.');

        $this->studentService->loginStudent($data);
    }

    public function testLoginStudentNotEnrolled() {
        $data = [
            'phone' => '1234567890',
            'password' => 'secret123'
        ];

        $student = [
            'id' => 1,
            'name' => 'John Doe',
            'phone' => '1234567890',
            'enrolled' => 0,
            'password_hash' => password_hash('secret123', PASSWORD_DEFAULT)
        ];

        $this->studentRepoMock->expects($this->once())
            ->method('findByPhone')
            ->with('1234567890')
            ->willReturn($student);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Invalid credentials or not enrolled.');

        $this->studentService->loginStudent($data);
    }

    public function testLoginStudentNotFound() {
        $data = [
            'phone' => '0000000000',
            'password' => 'secret123'
        ];

        $this->studentRepoMock->expects($this->once())
            ->method('findByPhone')
            ->with('0000000000')
            ->willReturn(null);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Invalid credentials or not enrolled.');

        $this->studentService->loginStudent($data);
    }

    public function testAddStudentSuccess() {
        $data = [
            'name' => 'Jane Doe',
            'phone' => '0987654321',
            'password' => 'newsecret'
        ];

        $this->studentRepoMock->expects($this->once())
            ->method('create')
            ->willReturn(2);

        $result = $this->studentService->addStudent($data);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals(2, $result['id']);
        $this->assertEquals('Jane Doe', $result['name']);
        $this->assertEquals('0987654321', $result['phone']);
    }

    public function testAddStudentDuplicatePhone() {
        $data = [
            'name' => 'Jane Doe',
            'phone' => '0987654321',
            'password' => 'newsecret'
        ];

        $exception = new \PDOException('SQLSTATE[23000]: Integrity constraint violation: 1062 Duplicate entry \'0987654321\' for key \'students_phone_unique\'');

        $this->studentRepoMock->expects($this->once())
            ->method('create')
            ->willThrowException($exception);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('A student with this Phone Number already exists.');
        $this->expectExceptionCode(400);

        $this->studentService->addStudent($data);
    }

    public function testAddStudentOtherPDOException() {
        $data = [
            'name' => 'Jane Doe',
            'phone' => '0987654321',
            'password' => 'newsecret'
        ];

        $exception = new \PDOException('Some other database error');

        $this->studentRepoMock->expects($this->once())
            ->method('create')
            ->willThrowException($exception);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Failed to add student: Some other database error');
        $this->expectExceptionCode(500);

        $this->studentService->addStudent($data);
    }

    public function testBulkImportSuccess() {
        $students = [
            ['name' => 'Alice', 'access_code' => 'A123'],
            ['name' => 'Bob', 'access_code' => 'B456']
        ];

        $this->studentRepoMock->expects($this->exactly(2))
            ->method('importStudent');

        $result = $this->studentService->bulkImport($students);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals(2, $result['imported']);
        $this->assertEmpty($result['errors']);
    }

    public function testBulkImportMissingData() {
        $students = [
            ['name' => 'Alice'], // missing access_code
            ['access_code' => 'B456'] // missing name
        ];

        $this->studentRepoMock->expects($this->never())
            ->method('importStudent');

        $result = $this->studentService->bulkImport($students);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals(0, $result['imported']);
        $this->assertCount(2, $result['errors']);
        $this->assertStringContainsString('missing name or access code', $result['errors'][0]);
        $this->assertStringContainsString('missing name or access code', $result['errors'][1]);
    }

    public function testBulkImportWithException() {
        $students = [
            ['name' => 'Alice', 'access_code' => 'A123']
        ];

        $this->studentRepoMock->expects($this->once())
            ->method('importStudent')
            ->willThrowException(new \Exception('Import failed'));

        $result = $this->studentService->bulkImport($students);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals(0, $result['imported']);
        $this->assertCount(1, $result['errors']);
        $this->assertStringContainsString('Import failed', $result['errors'][0]);
    }
}
