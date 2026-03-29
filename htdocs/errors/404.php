<?php
$code = 404;
$titleKey = 'err404Title';
$descKey  = 'err404Desc';
$primaryHref = '/';
$primaryKey  = 'backHome';
$secondaryAction = ['type' => 'js', 'js' => 'history.back()', 'key' => 'goBack'];
require __DIR__ . '/_error_template.php';
