<?php
namespace Tests\Services;

use PHPUnit\Framework\TestCase;
use App\Services\AuthService;
use App\Repositories\AdminRepository;

class AuthServiceTest extends TestCase {
    private $adminRepoMock;
    private $authService;

    protected function setUp(): void {
        $this->adminRepoMock = $this->createMock(AdminRepository::class);
        $this->authService = new AuthService($this->adminRepoMock);
    }

    public function testAuthenticateSuccess() {
        $password = 'secret123';
        $hash = password_hash($password, PASSWORD_DEFAULT);

        $this->adminRepoMock->method('findByUsername')
            ->with('admin')
            ->willReturn([
                'id' => 1,
                'username' => 'admin',
                'password_hash' => $hash
            ]);

        $result = $this->authService->authenticate('admin', $password);

        $this->assertIsArray($result);
        $this->assertArrayHasKey('admin', $result);
        $this->assertEquals(1, $result['admin']['id']);
        $this->assertEquals('admin', $result['admin']['username']);
        $this->assertFalse($result['is_default']);
    }

    public function testAuthenticateWithDefaultPassword() {
        $password = 'password';
        $hash = password_hash($password, PASSWORD_DEFAULT);

        $this->adminRepoMock->method('findByUsername')
            ->with('admin')
            ->willReturn([
                'id' => 1,
                'username' => 'admin',
                'password_hash' => $hash
            ]);

        $result = $this->authService->authenticate('admin', $password);

        $this->assertIsArray($result);
        $this->assertTrue($result['is_default']);
    }

    public function testAuthenticateInvalidUsername() {
        $this->adminRepoMock->method('findByUsername')
            ->with('unknown')
            ->willReturn(false);

        $result = $this->authService->authenticate('unknown', 'password');

        $this->assertEquals(["error" => "Invalid username or password"], $result);
    }

    public function testAuthenticateInvalidPassword() {
        $hash = password_hash('correct_password', PASSWORD_DEFAULT);

        $this->adminRepoMock->method('findByUsername')
            ->with('admin')
            ->willReturn([
                'id' => 1,
                'username' => 'admin',
                'password_hash' => $hash
            ]);

        $result = $this->authService->authenticate('admin', 'wrong_password');

        $this->assertEquals(["error" => "Invalid username or password"], $result);
    }

    public function testApiLoginSuccess() {
        $password = 'secret123';
        $hash = password_hash($password, PASSWORD_DEFAULT);

        $this->adminRepoMock->method('findByUsername')
            ->with('admin')
            ->willReturn([
                'id' => 1,
                'username' => 'admin',
                'password_hash' => $hash
            ]);

        $this->adminRepoMock->expects($this->once())
            ->method('createToken')
            ->with($this->equalTo(1), $this->isType('string'), $this->isType('string'));

        $result = $this->authService->apiLogin('admin', $password);

        $this->assertEquals('success', $result['status']);
        $this->assertEquals(1, $result['admin']['id']);
        $this->assertArrayHasKey('token', $result);
    }

    public function testApiLoginFailure() {
        $this->adminRepoMock->method('findByUsername')
            ->with('unknown')
            ->willReturn(false);

        $this->adminRepoMock->expects($this->never())
            ->method('createToken');

        $result = $this->authService->apiLogin('unknown', 'password');

        $this->assertEquals(["error" => "Invalid username or password"], $result);
    }

    public function testRegisterFirstAdminAlreadyExists() {
        $this->adminRepoMock->method('countAdmins')->willReturn(1);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage("Admin already exists.");

        $this->authService->registerFirstAdmin('admin', 'password123');
    }

    public function testRegisterFirstAdminPasswordTooShort() {
        $this->adminRepoMock->method('countAdmins')->willReturn(0);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage("Password must be 6+ chars.");

        $this->authService->registerFirstAdmin('admin', 'short');
    }

    public function testRegisterFirstAdminSuccess() {
        $this->adminRepoMock->method('countAdmins')->willReturn(0);

        $this->adminRepoMock->expects($this->once())
            ->method('createAdmin')
            ->with($this->equalTo('admin'), $this->isType('string'));

        // We need to mock findByUsername since it's called by authenticate()
        $this->adminRepoMock->method('findByUsername')
            ->with('admin')
            ->willReturnCallback(function($username) {
                return [
                    'id' => 1,
                    'username' => $username,
                    // The hash created in registerFirstAdmin isn't accessible here easily
                    // So we'll just mock it as if the newly created hash matches the password
                    'password_hash' => password_hash('password123', PASSWORD_DEFAULT)
                ];
            });

        $result = $this->authService->registerFirstAdmin('admin', 'password123');

        $this->assertArrayHasKey('admin', $result);
        $this->assertEquals('admin', $result['admin']['username']);
    }

    public function testCheckTelegramLoginSuccess() {
        $this->adminRepoMock->method('findTelegramSession')
            ->with('session_123')
            ->willReturn(['session_id' => 'session_123', 'status' => 'authenticated']);

        $result = $this->authService->checkTelegramLogin('session_123');

        $this->assertEquals('success', $result['status']);
        $this->assertEquals('session_123', $result['data']['session_id']);
    }

    public function testCheckTelegramLoginNotFound() {
        $this->adminRepoMock->method('findTelegramSession')
            ->with('session_123')
            ->willReturn(false);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage("Session not found");
        $this->expectExceptionCode(404);

        $this->authService->checkTelegramLogin('session_123');
    }

    public function testInitTelegramSession() {
        $this->adminRepoMock->expects($this->once())
            ->method('createTelegramSession')
            ->with('session_123');

        $this->authService->initTelegramSession('session_123');
    }

    public function testVerifyTelegramCallbackMissingHash() {
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage("Hash is missing from Telegram payload");

        $this->authService->verifyTelegramCallback(['id' => 123], 'bot_token', 'session_123');
    }

    public function testVerifyTelegramCallbackInvalidHash() {
        $authData = [
            'id' => 123,
            'first_name' => 'John',
            'auth_date' => time(),
            'hash' => 'invalid_hash'
        ];

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage("Data is NOT from Telegram (Hash verification failed)");

        $this->authService->verifyTelegramCallback($authData, 'bot_token', 'session_123');
    }

    public function testVerifyTelegramCallbackOutdated() {
        // First we need to construct a valid hash to bypass the hash check
        $authData = [
            'id' => 123,
            'first_name' => 'John',
            'auth_date' => time() - 86401, // > 86400 seconds ago
        ];

        $dataCheckArr = [];
        foreach ($authData as $key => $value) {
            $dataCheckArr[] = $key . '=' . $value;
        }
        sort($dataCheckArr);
        $dataCheckString = implode("\n", $dataCheckArr);

        $secretKey = hash('sha256', 'bot_token', true);
        $validHash = hash_hmac('sha256', $dataCheckString, $secretKey);

        $authData['hash'] = $validHash;

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage("Data is outdated");

        $this->authService->verifyTelegramCallback($authData, 'bot_token', 'session_123');
    }

    public function testVerifyTelegramCallbackSuccess() {
        $authData = [
            'id' => 123,
            'first_name' => 'John',
            'auth_date' => time(),
        ];

        $dataCheckArr = [];
        foreach ($authData as $key => $value) {
            $dataCheckArr[] = $key . '=' . $value;
        }
        sort($dataCheckArr);
        $dataCheckString = implode("\n", $dataCheckArr);

        $secretKey = hash('sha256', 'bot_token', true);
        $validHash = hash_hmac('sha256', $dataCheckString, $secretKey);

        $authData['hash'] = $validHash;

        $expectedAuthData = $authData;
        unset($expectedAuthData['hash']);

        $this->adminRepoMock->expects($this->once())
            ->method('updateTelegramSession')
            ->with('session_123', $expectedAuthData);

        $result = $this->authService->verifyTelegramCallback($authData, 'bot_token', 'session_123');

        $this->assertEquals($expectedAuthData, $result);
    }
}
