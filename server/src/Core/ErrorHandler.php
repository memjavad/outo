<?php
namespace App\Core;

class ErrorHandler {
    
    public static function register() {
        // Hide standard errors from directly outputting to screen
        ini_set('display_errors', '0');
        error_reporting(E_ALL);

        set_error_handler([self::class, 'handleError']);
        set_exception_handler([self::class, 'handleException']);
        register_shutdown_function([self::class, 'handleFatalError']);
    }

    public static function handleError($level, $message, $file, $line) {
        // Respect error reporting level
        if (error_reporting() & $level) {
            throw new \ErrorException($message, 0, $level, $file, $line);
        }
        return false;
    }

    public static function handleException(\Throwable $exception) {
        self::logError($exception);
        
        $code = $exception->getCode();
        if ($code != 404 && $code != 401 && $code != 400 && $code != 403) {
            $code = 500;
        }

        self::respond($code, $exception->getMessage());
    }

    public static function handleFatalError() {
        $error = error_get_last();
        if ($error !== null && in_array($error['type'], [E_ERROR, E_CORE_ERROR, E_COMPILE_ERROR, E_PARSE])) {
            self::logError(new \ErrorException($error['message'], 0, $error['type'], $error['file'], $error['line']));
            self::respond(500, "Fatal Internal Error");
        }
    }

    private static function logError(\Throwable $exception) {
        try {
            $logDir = __DIR__ . '/../../logs';
            if (!is_dir($logDir)) {
                @mkdir($logDir, 0777, true);
            }

            $logFile = $logDir . '/error.log';
            $timestamp = date('Y-m-d H:i:s');
            $message = sprintf(
                "[%s] %s: %s in %s:%d\nStack trace:\n%s\n\n",
                $timestamp,
                get_class($exception),
                $exception->getMessage(),
                $exception->getFile(),
                $exception->getLine(),
                $exception->getTraceAsString()
            );

            @error_log($message, 3, $logFile);
        } catch (\Throwable $t) {
            // Failsafe exit to prevent double exception silent drops
        }
    }

    private static function respond($code, $message) {
        if (!headers_sent()) {
            http_response_code($code);
            header('Content-Type: application/json');
        }
        
        // In production, mask the absolute error message for 500s unless debugging
        // For now, we'll return a generic message for hard 500s to avoid leaking DB schema/paths to users
        $outputMessage = ($code === 500) ? "Internal Server Error" : $message;

        echo json_encode([
            'status' => 'error',
            'error' => $outputMessage
        ]);
        exit;
    }
}
