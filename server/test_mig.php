<?php
require 'index.php'; // Initializes Dotenv and Autoloader
$db = \App\Core\Database::getInstance();
$m = new \App\Core\Migrator($db);
print_r($m->up());
