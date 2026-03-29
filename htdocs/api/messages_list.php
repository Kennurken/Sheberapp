<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
$uid = (int)$user['id'];
$orderId = get_int('order_id', 0);
$afterId = (int)($_GET['after_id'] ?? 0);
if ($orderId <= 0) json_out(['ok' => false, 'error' => 'validation'], 422);

try {
  // Проверяем, что пользователь участник заказа
  $st = $pdo->prepare("SELECT client_id, master_id FROM orders WHERE id = ? LIMIT 1");
  $st->execute([$orderId]);
  $o = $st->fetch();
  if (!$o) json_out(['ok' => false, 'error' => 'not_found'], 404);
  $clientId = (int)$o['client_id'];
  $masterId = (int)($o['master_id'] ?? 0);
  if ($clientId !== $uid && $masterId !== $uid) json_out(['ok' => false, 'error' => 'forbidden'], 403);

  $otherId = ($uid === $clientId) ? $masterId : $clientId;
  $otherOnline = false;
  $otherLastSeen = null;
  if ($otherId > 0) {
    try {
      $st2 = $pdo->prepare('SELECT last_seen FROM users WHERE id = ? LIMIT 1');
      $st2->execute([$otherId]);
      $ls = $st2->fetchColumn();
      if ($ls) {
        $otherLastSeen = (string)$ls;
        $ts = strtotime($otherLastSeen);
        if ($ts && (time() - $ts) <= 120) $otherOnline = true;
      }
    } catch (Throwable $e) {}
  }

  // Автомиграция: безопасно добавляем колонки по одной (совместимо с MySQL 5.7+)
  $needed = ['msg_type', 'file_url', 'read_at'];
  try {
    $cols = $pdo->query("SHOW COLUMNS FROM order_messages")->fetchAll(PDO::FETCH_COLUMN, 0);
    $colList = array_map('strtolower', $cols);
    if (!in_array('msg_type', $colList)) {
      $pdo->exec("ALTER TABLE order_messages ADD COLUMN msg_type VARCHAR(16) NOT NULL DEFAULT 'text'");
    }
    if (!in_array('file_url', $colList)) {
      $pdo->exec("ALTER TABLE order_messages ADD COLUMN file_url VARCHAR(255) NULL DEFAULT NULL");
    }
    if (!in_array('is_read', $colList)) {
      $pdo->exec("ALTER TABLE order_messages ADD COLUMN is_read TINYINT(1) NOT NULL DEFAULT 0");
    }
    if (!in_array('read_at', $colList)) {
      $pdo->exec("ALTER TABLE order_messages ADD COLUMN read_at DATETIME NULL DEFAULT NULL");
    }
  } catch (Throwable $migErr) {
    error_log('[messages_list] migration error: ' . $migErr->getMessage());
  }

  // Определяем какие колонки реально есть для безопасного SELECT
  $hasExtra = true;
  try {
    $pdo->query("SELECT msg_type FROM order_messages LIMIT 0");
  } catch (Throwable $e) {
    $hasExtra = false;
  }

  if ($hasExtra) {
    $sql = "SELECT id, order_id, sender_id, message AS body,
            COALESCE(msg_type,'text') AS msg_type,
            COALESCE(file_url,'') AS file_url,
            COALESCE(is_read,0) AS is_read,
            COALESCE(read_at,'') AS read_at,
            is_system, created_at FROM order_messages WHERE order_id = ?";
  } else {
    // Fallback: базовые колонки только
    $sql = "SELECT id, order_id, sender_id, message AS body,
            'text' AS msg_type, '' AS file_url,
            0 AS is_read, '' AS read_at,
            is_system, created_at FROM order_messages WHERE order_id = ?";
  }

  $params = [$orderId];
  if ($afterId > 0) {
    $sql .= " AND id > ?";
    $params[] = $afterId;
  }
  $sql .= " ORDER BY id ASC LIMIT 200";

  $st = $pdo->prepare($sql);
  $st->execute($params);
  $msgs = $st->fetchAll() ?: [];

  json_out(['ok' => true, 'data' => ['me' => $uid, 'messages' => $msgs, 'other' => ['id' => $otherId, 'online' => $otherOnline ? 1 : 0, 'last_seen' => $otherLastSeen]]]);
} catch (Throwable $e) {
  error_log('[messages_list] FATAL: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine());
  json_out(['ok' => false, 'error' => 'db_error'], 500);
}
