<?php
namespace App\Middleware;

use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;
use Psr\Http\Message\ResponseInterface as Response;
use App\Services\SecurityService;

class SecurityMiddleware {
    private SecurityService $securityService;

    public function __construct(SecurityService $securityService) {
        $this->securityService = $securityService;
    }

    public function __invoke(Request $request, RequestHandler $handler): Response {
        $serverParams = $request->getServerParams();
        $clientIp = $serverParams['REMOTE_ADDR'] ?? '0.0.0.0';

        // Security constraints will throw HTTP Exceptions caught by Slim
        $this->securityService->enforceRateLimits($clientIp, 'api', 200);
        $this->securityService->enforceIpWhitelist($clientIp);

        // Resolve Identities
        $authHeader = $request->getHeaderLine('Authorization');
        $apiKey = $request->getHeaderLine('X-API-Key') ?: ($request->getQueryParams()['api_key'] ?? null);
        $sessionData = $_SESSION ?? [];

        $authData = $this->securityService->resolveAuthentication($authHeader, $apiKey, $sessionData);
        
        $request = $request->withAttribute('is_admin', $authData['is_admin'])
                           ->withAttribute('admin_id', $authData['admin_id'])
                           ->withAttribute('student_id', $authData['student_id']);

        return $handler->handle($request);
    }
}
