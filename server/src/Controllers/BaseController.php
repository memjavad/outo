<?php
namespace App\Controllers;

use Psr\Http\Message\ResponseInterface as Response;

abstract class BaseController {
    protected function json(Response $response, $data, $statusCode = 200): Response {
        $response->getBody()->write(json_encode($data));
        return $response->withStatus($statusCode)
                        ->withHeader('Content-Type', 'application/json');
    }

    protected function getRequestBody() {
        return json_decode(file_get_contents("php://input"), true);
    }
}
