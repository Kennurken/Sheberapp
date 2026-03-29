<?php
declare(strict_types=1);
require __DIR__ . '/../init.php';

header('Content-Type: application/json; charset=utf-8');

$user = current_user($pdo);
if (!$user) {
    echo json_encode(['ok' => false, 'error' => 'not_logged_in']);
    exit;
}

// Обновляем last_seen
try {
    $pdo->prepare('UPDATE users SET last_seen = NOW() WHERE id = ?')->execute([(int)$user['id']]);
} catch (Throwable) {}

echo json_encode(['ok' => true]);