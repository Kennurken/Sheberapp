<?php
$code = 401;
$titleKey = 'err401Title';
$descKey  = 'err401Desc';
$primaryHref = '/login.php';
$primaryKey  = 'login';
$secondaryAction = ['type' => 'link', 'href' => '/', 'key' => 'backHome'];
require __DIR__ . '/_error_template.php';
