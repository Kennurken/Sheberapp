<?php
declare(strict_types=1);

// Возвращает данные одного заказа для открытия чата.
// ВАЖНО: фронт (index.js) ожидает JSON: { ok:true, data: {...} }

require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
$uid = (int)$user['id'];

$orderId = get_int('order_id', 0);
if ($orderId <= 0) json_out(['ok'=>false,'error'=>'validation'], 422);

try {
  try {
    $pdo->exec("ALTER TABLE orders ADD COLUMN IF NOT EXISTS client_lat DECIMAL(9,6) NULL");
    $pdo->exec("ALTER TABLE orders ADD COLUMN IF NOT EXISTS client_lng DECIMAL(9,6) NULL");
  } catch (Throwable $_e) {}

  $st = $pdo->prepare("
    SELECT
      o.*,
      COALESCE(u1.name, o.guest_name, 'Гость') AS client_name,
      u1.avatar_url AS client_avatar_url,
      COALESCE(u1.avatar_color,'#1cb7ff') AS client_avatar_color,
      COALESCE(u1.phone, o.guest_phone, '') AS client_phone,
      u2.name AS master_name,
      u2.avatar_url AS master_avatar_url,
      COALESCE(u2.avatar_color,'#1cb7ff') AS master_avatar_color,
      mc.name AS category_name,
      -- title для UI: категория или первая строка системного сообщения
      COALESCE(
        mc.name,
        NULLIF(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(fs.message, '\\n', 1), ':', -1)), ''),
        'Заказ'
      ) AS service_title,
      -- флаг наличия отзыва по заказу
      (r.id IS NOT NULL) AS review_exists,
      COALESCE(odc.cnt, 0) AS client_done,
      COALESCE(odm.cnt, 0) AS master_done
    FROM orders o
    LEFT JOIN users u1 ON u1.id = o.client_id
    LEFT JOIN users u2 ON u2.id = o.master_id
    LEFT JOIN master_categories mc ON mc.id = o.category_id
    LEFT JOIN order_messages fs ON fs.id = (
      SELECT mm2.id FROM order_messages mm2
      WHERE mm2.order_id = o.id AND mm2.is_system = 1
      ORDER BY mm2.id ASC LIMIT 1
    )
    LEFT JOIN reviews r ON r.order_id = o.id
    LEFT JOIN (
      SELECT order_id, COUNT(*) AS cnt FROM order_done WHERE done_by = 'client' GROUP BY order_id
    ) odc ON odc.order_id = o.id
    LEFT JOIN (
      SELECT order_id, COUNT(*) AS cnt FROM order_done WHERE done_by = 'master' GROUP BY order_id
    ) odm ON odm.order_id = o.id
    WHERE o.id = ?
    LIMIT 1
  ");
  $st->execute([$orderId]);
  $o = $st->fetch(PDO::FETCH_ASSOC);
  if (!$o) json_out(['ok'=>false,'error'=>'not_found'], 404);

  $isClient = ((int)$o['client_id'] === $uid);
  $isMaster = ((int)($o['master_id'] ?? 0) === $uid);
  if (!$isClient && !$isMaster) json_out(['ok'=>false,'error'=>'forbidden'], 403);

  // Нормализация булевых флагов
  $o['review_exists'] = (int)($o['review_exists'] ?? 0);
  $o['client_done'] = (int)($o['client_done'] ?? 0);
  $o['master_done'] = (int)($o['master_done'] ?? 0);

  $clat = $o['client_lat'] ?? null;
  $clng = $o['client_lng'] ?? null;
  $o['client_lat'] = ($clat !== null && $clat !== '' && is_numeric($clat)) ? (float)$clat : null;
  $o['client_lng'] = ($clng !== null && $clng !== '' && is_numeric($clng)) ? (float)$clng : null;

  // Attach photos (best-effort)
  try {
    $stp = $pdo->prepare("SELECT file_path FROM order_photos WHERE order_id = ? ORDER BY id ASC");
    $stp->execute([$orderId]);
    $o['photos'] = array_map(fn($r) => '/' . ltrim((string)$r['file_path'], '/'), $stp->fetchAll(PDO::FETCH_ASSOC) ?: []);
  } catch (Throwable $e) {
    $o['photos'] = [];
  }

  json_out(['ok'=>true,'data'=>$o]);
} catch (Throwable $e) {
  json_out(['ok'=>false,'error'=>'db_error'], 500);
}
