<?php
$url = 'https://s.nabuo.org/server/api.php?action=student_login';
$data = ['phone' => '1234567890', 'password' => 'test'];

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
if(curl_errno($ch)){
    echo "CURL Error: " . curl_error($ch);
} else {
    echo "HTTP CODE: $httpCode\n";
    echo "RESPONSE BODY:\n$response\n";
}
curl_close($ch);
