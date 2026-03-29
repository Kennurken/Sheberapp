<?php
$code = 403;
$titleKey = 'err403Title';
$descKey  = 'err403Desc';
$primaryHref = '/';
$primaryKey  = 'backHome';
$secondaryAction = ['type' => 'js', 'js' => 'history.back()', 'key' => 'goBack'];
require __DIR__ . '/_error_template.php';
