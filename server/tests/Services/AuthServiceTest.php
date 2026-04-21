<?php
namespace Tests\Services;

use PHPUnit\Framework\TestCase;
use App\Services\AuthService;
use App\Repositories\AdminRepository;

class AuthServiceTest extends TestCase {

    private $adminRepoMock;
    private AuthService $authService;

    protected function setUp(): void {
        $this->adminRepoMock = $this->createMock(AdminRepository::class);
        $this->authService = new AuthService($this->adminRepoMock);
    }

    public function testAuthenticateValidCredentials() {
        $username = 'admin';
        $password = 'password123';
        $hash = password_hash($password, PASSWORD_DEFAULT);

        $this->adminRepoMock->method('findByUsername')
            ->with($username)
            ->willReturn(['id' => 1, 'username' => $username, 'password_hash' => $hash]);

        $result = $this->authService->authenticate($username, $password);

        $this->assertArrayNotHasKey('error', $result);
        $this->assertEquals(1, $result['admin']['id']);
        $this->assertEquals($username, $result['admin']['username']);
        $this->assertFalse($result['is_default']);
    }

    public function testAuthenticateInvalidPassword() {
        $username = 'admin';
        $password = 'wrong_password';
        $hash = password_hash('password123', PASSWORD_DEFAULT);

        $this->adminRepoMock->method('findByUsername')
            ->with($username)
            ->willReturn(['id' => 1, 'username' => $username, 'password_hash' => $hash]);

        $result = $this->authService->authenticate($username, $password);

        $this->assertArrayHasKey('error', $result);
        $this->assertEquals('Invalid username or password', $result['error']);
    }

    public function testAuthenticateUserNotFound() {
        $username = 'admin';
        $password = 'password123';

        $this->adminRepoMock->method('findByUsername')
            ->with($username)
            ->willReturn(false);

        $result = $this->authService->authenticate($username, $password);

        $this->assertArrayHasKey('error', $result);
        $this->assertEquals('Invalid username or password', $result['error']);
    }

    public function testApiLoginSuccess() {
        $username = 'admin';
        $password = 'password123';
        $hash = password_hash($password, PASSWORD_DEFAULT);

        $this->adminRepoMock->method('findByUsername')
            ->with($username)
            ->willReturn(['id' => 1, 'username' => $username, 'password_hash' => $hash]);

        $this->adminRepoMock->expects($this->once())
            ->method('createToken')
            ->with($this->equalTo(1), $this->isType('string'), $this->isType('string'));

        $result = $this->authService->apiLogin($username, $password);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals(1, $result['admin']['id']);
        $this->assertArrayHasKey('token', $result);
    }

    public function testRegisterFirstAdminSuccess() {
        $username = 'admin';
        $password = 'password123';

        $this->adminRepoMock->method('countAdmins')
            ->willReturn(0);

        $this->adminRepoMock->expects($this->once())
            ->method('createAdmin')
            ->with($username, $this->isType('string'));

        // We mock findByUsername to return the newly created user when authenticate is called internally
        $this->adminRepoMock->method('findByUsername')
            ->willReturn(['id' => 1, 'username' => $username, 'password_hash' => password_hash($password, PASSWORD_DEFAULT)]);

        $result = $this->authService->registerFirstAdmin($username, $password);

        $this->assertArrayNotHasKey('error', $result);
        $this->assertEquals($username, $result['admin']['username']);
    }

    public function testRegisterFirstAdminFailsIfAdminExists() {
        $this->adminRepoMock->method('countAdmins')
            ->willReturn(1);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Admin already exists.');

        $this->authService->registerFirstAdmin('admin', 'password123');
    }

    public function testRegisterFirstAdminFailsIfPasswordTooShort() {
        $this->adminRepoMock->method('countAdmins')
            ->willReturn(0);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Password must be 6+ chars.');

        $this->authService->registerFirstAdmin('admin', '12345');
    }

    public function testCheckTelegramLoginSuccess() {
        $sessionId = 'session123';
        $sessionData = ['session_id' => $sessionId, 'status' => 'authenticated'];

        $this->adminRepoMock->method('findTelegramSession')
            ->with($sessionId)
            ->willReturn($sessionData);

        $result = $this->authService->checkTelegramLogin($sessionId);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals($sessionData, $result['data']);
    }

    public function testCheckTelegramLoginNotFound() {
        $sessionId = 'session123';

        $this->adminRepoMock->method('findTelegramSession')
            ->with($sessionId)
            ->willReturn(false);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Session not found');
        $this->expectExceptionCode(404);

        $this->authService->checkTelegramLogin($sessionId);
    }

    public function testInitTelegramSession() {
        $sessionId = 'session123';

        $this->adminRepoMock->expects($this->once())
            ->method('createTelegramSession')
            ->with($sessionId);

        $this->authService->initTelegramSession($sessionId);
    }

    public function testVerifyTelegramCallbackFailsIfNoHash() {
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Hash is missing from Telegram payload');

        $this->authService->verifyTelegramCallback(['id' => 123], 'botToken', 'session123');
    }

    public function testVerifyTelegramCallbackFailsIfInvalidHash() {
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Data is NOT from Telegram (Hash verification failed)');

        $this->authService->verifyTelegramCallback(['id' => 123, 'hash' => 'invalid_hash'], 'botToken', 'session123');
    }

    public function testVerifyTelegramCallbackFailsIfOutdated() {
        // Need a valid hash for an outdated timestamp
        $botToken = 'botToken';
        $authData = [
            'id' => 123,
            'auth_date' => time() - 86401 // 1 second more than 24 hours ago
        ];

        $dataCheckArr = [];
        foreach ($authData as $key => $value) {
            $dataCheckArr[] = $key . '=' . $value;
        }
        sort($dataCheckArr);
        $dataCheckString = implode("\n", $dataCheckArr);

        $secretKey = hash('sha256', $botToken, true);
        $hash = hash_hmac('sha256', $dataCheckString, $secretKey);

        $authData['hash'] = $hash;

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Data is outdated');

        $this->authService->verifyTelegramCallback($authData, $botToken, 'session123');
    }

    public function testVerifyTelegramCallbackSuccess() {
        $botToken = 'botToken';
        $sessionId = 'session123';
        $authData = [
            'id' => 123,
            'first_name' => 'John',
            'auth_date' => time()
        ];

        $dataCheckArr = [];
        foreach ($authData as $key => $value) {
            $dataCheckArr[] = $key . '=' . $value;
        }
        sort($dataCheckArr);
        $dataCheckString = implode("\n", $dataCheckArr);

        $secretKey = hash('sha256', $botToken, true);
        $hash = hash_hmac('sha256', $dataCheckString, $secretKey);

        $authData['hash'] = $hash;

        $this->adminRepoMock->expects($this->once())
            ->method('updateTelegramSession')
            ->with($sessionId, $this->isType('array'));

        $result = $this->authService->verifyTelegramCallback($authData, $botToken, $sessionId);

        // Output shouldn't have hash or session_id if they were provided (in this case session_id wasn't in authData initially)
        $this->assertArrayNotHasKey('hash', $result);
        $this->assertEquals(123, $result['id']);
        $this->assertEquals('John', $result['first_name']);
    }
}
