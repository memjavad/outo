<?php
$url = 'https://s.nabuo.org/server/api.php?action=student_login';
$data = json_encode(['email' => '+1234567890', 'password' => 'testpassword']);

$options = [
    'http' => [
        'header'  => "Content-type: application/json\r\n",
        'method'  => 'POST',
        'content' => $data,
        'ignore_errors' => true
    ],
    'ssl' => [
        'verify_peer' => false,
        'verify_peer_name' => false,
    ]
];

$context  = stream_context_create($options);
$result = file_get_contents($url, false, $context);
echo "RESPONSE FROM LIVE SERVER WHEN MISSING PHONE:\n";
echo $result;
