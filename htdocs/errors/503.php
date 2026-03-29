<?php
$code = 503;
$titleKey = 'err503Title';
$descKey  = 'err503Desc';
$primaryHref = '/';
$primaryKey  = 'backHome';
$secondaryAction = ['type' => 'js', 'js' => 'location.reload()', 'key' => 'tryAgain'];
require __DIR__ . '/_error_template.php';
