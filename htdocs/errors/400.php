<?php
$code = 400;
$titleKey = 'err400Title';
$descKey  = 'err400Desc';
$primaryHref = '/';
$primaryKey  = 'backHome';
$secondaryAction = ['type' => 'js', 'js' => 'location.reload()', 'key' => 'tryAgain'];
require __DIR__ . '/_error_template.php';
