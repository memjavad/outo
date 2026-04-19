<?php
require __DIR__ . '/vendor/autoload.php';

use Ratchet\Server\IoServer;
use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use App\WebSockets\MonitorServer;

$port = 8080;

$server = IoServer::factory(
    new HttpServer(
        new WsServer(
            new MonitorServer()
        )
    ),
    $port
);

echo "WebSocket Server running on port {$port}... Listening for Admin connections.\n";
$server->run();
