<?php
require 'server/vendor/autoload.php';
$db = App\Core\Database::getInstance();
$r = new App\Repositories\ResultRepository($db);
echo json_encode($r->getStudentResults(1));
