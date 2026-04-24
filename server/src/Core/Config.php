<?php
namespace App\Core;

class Config {
    private static $envLoaded = false;

    private static function init() {
        if (!self::$envLoaded) {
            $dotenvPath = realpath(__DIR__ . '/../../');
            if (file_exists($dotenvPath . '/.env')) {
                $dotenv = \Dotenv\Dotenv::createImmutable($dotenvPath);
                $dotenv->safeLoad();
            }
            self::$envLoaded = true;
        }
    }

    public static function get($key, $default = null) {
        self::init();
        
        $config = [
            'db_host' => $_ENV['DB_HOST'] ?? 'localhost',
            'db_name' => $_ENV['DB_NAME'] ?? 's_ss',
            'db_user' => $_ENV['DB_USER'] ?? 's_ss',
            'db_pass' => $_ENV['DB_PASS'] ?? '',
            'jwt_secret' => $_ENV['JWT_SECRET'] ?? '',
            'token_expiry' => $_ENV['TOKEN_EXPIRY'] ?? 86400
        ];
        
        return $config[$key] ?? $default;
    }
}
