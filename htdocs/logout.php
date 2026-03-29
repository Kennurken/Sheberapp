<?php
declare(strict_types=1);
require __DIR__ . '/init.php';

session_destroy();
setcookie(session_name(), '', ['expires' => time() - 3600, 'path' => '/', 'samesite' => 'Lax']);
redirect('index.php?auth=logout');