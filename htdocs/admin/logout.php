<?php
declare(strict_types=1);
require __DIR__ . '/../init.php';
unset($_SESSION['is_admin']);
header('Location: /admin/login.php');
exit;
