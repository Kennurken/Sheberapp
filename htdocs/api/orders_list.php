<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);
$uid = (int)$user['id'];

$limit = (int)($_GET['limit'] ?? 50);
if ($limit < 1) $limit = 50;
if ($limit > 100) $limit = 100;

/**
 * Возвращаем список заказов для вкладки "Сообщения".
 * ВАЖНО: index.js исторически ожидает поля:
 * - service_title
 * - last_message, last_message_at
 * - client_name, master_name
 * - client_done, master_done (для кнопки "Завершить")
 *
 * В вашей текущей схеме этих колонок нет —
 * мы формируем их виртуально:
 * - service_title берём из категории, либо из первого системного сообщения "Заказ: ..."
 * - *_done считаем по таблице order_done (после применения миграции v3)
 */

// Ensure order_done table exists (DDL outside main query to avoid MySQL errors)
try {
  $pdo->exec("CREATE TABLE IF NOT EXISTS order_done (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    done_by ENUM('client','master') NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_order_done (order_id, done_by)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
} catch (Throwable $e) {}

try {
  try {
    $pdo->exec("ALTER TABLE orders ADD COLUMN IF NOT EXISTS client_lat DECIMAL(9,6) NULL");
    $pdo->exec("ALTER TABLE orders ADD COLUMN IF NOT EXISTS client_lng DECIMAL(9,6) NULL");
  } catch (Throwable $_e) {}

  $sql = "
    SELECT
      o.id,
      o.client_id,
      o.master_id,
      o.category_id,
      o.description,
      o.address,
      o.client_lat,
      o.client_lng,
      COALESCE(o.city, c.city, '') AS city,
      COALESCE(o.guest_name, '') AS guest_name,
      COALESCE(o.guest_phone, '') AS guest_phone,
      COALESCE(o.is_guest_order, 0) AS is_guest_order,
      o.price,
      o.status,
      o.created_at,
      o.accepted_at,
      o.completed_at,
      o.updated_at,
      COALESCE(c.name, o.guest_name, 'Гость') AS client_name,
      c.avatar_url AS client_avatar_url,
      COALESCE(c.avatar_color,'#1cb7ff') AS client_avatar_color,
      COALESCE(c.phone, o.guest_phone, '') AS client_phone,
      m.name AS master_name,
      m.avatar_url AS master_avatar_url,
      COALESCE(m.avatar_color,'#1cb7ff') AS master_avatar_color,
      mc.name AS category_name,
      -- title для UI: категория или первая строка системного сообщения
      COALESCE(
        mc.name,
        NULLIF(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(fs.message, '\n', 1), ':', -1)), ''),
        'Заказ'
      ) AS service_title,
      lm.message AS last_message,
      lm.created_at AS last_message_at,
      -- done flags (нормально работают после db_fix_v3.sql)
      COALESCE(odc.cnt, 0) AS client_done,
      COALESCE(odm.cnt, 0) AS master_done
    FROM orders o
    LEFT JOIN users c ON c.id = o.client_id
    LEFT JOIN users m ON m.id = o.master_id
    LEFT JOIN master_categories mc ON mc.id = o.category_id
    LEFT JOIN order_messages lm ON lm.id = (
      SELECT mm.id FROM order_messages mm
      WHERE mm.order_id = o.id
      ORDER BY mm.id DESC LIMIT 1
    )
    LEFT JOIN order_messages fs ON fs.id = (
      SELECT mm2.id FROM order_messages mm2
      WHERE mm2.order_id = o.id AND mm2.is_system = 1
      ORDER BY mm2.id ASC LIMIT 1
    )
    LEFT JOIN (
      SELECT order_id, COUNT(*) AS cnt FROM order_done WHERE done_by = 'client' GROUP BY order_id
    ) odc ON odc.order_id = o.id
    LEFT JOIN (
      SELECT order_id, COUNT(*) AS cnt FROM order_done WHERE done_by = 'master' GROUP BY order_id
    ) odm ON odm.order_id = o.id
    WHERE o.client_id = ? OR o.master_id = ?
    ORDER BY COALESCE(lm.created_at, o.updated_at, o.created_at) DESC
    LIMIT {$limit}
  ";

  $st = $pdo->prepare($sql);
  $st->execute([$uid, $uid]);
  $rows = $st->fetchAll() ?: [];

  // Attach photos (best-effort)
  try {
    $ids = array_values(array_unique(array_map(fn($r) => (int)($r['id'] ?? 0), $rows)));
    $ids = array_filter($ids, fn($v) => $v > 0);
    if (count($ids) > 0) {
      $in = implode(',', array_fill(0, count($ids), '?'));
      $stp = $pdo->prepare("SELECT order_id, file_path FROM order_photos WHERE order_id IN ($in) ORDER BY id ASC");
      $stp->execute($ids);
      $map = [];
      foreach (($stp->fetchAll(PDO::FETCH_ASSOC) ?: []) as $p) {
        $oid = (int)($p['order_id'] ?? 0);
        $fp = (string)($p['file_path'] ?? '');
        if ($oid > 0 && $fp !== '') {
          $url = '/' . ltrim($fp, '/');
          $map[$oid][] = $url;
        }
      }
      foreach ($rows as &$r) {
        $oid = (int)($r['id'] ?? 0);
        $r['photos'] = $map[$oid] ?? [];
      }
      unset($r);
    }
  } catch (Throwable $e) {
    // table may not exist; ignore
  }

  json_out(['ok' => true, 'data' => $rows]);
} catch (Throwable $e) {
  json_out(['ok' => false, 'error' => 'db_error'], 500);
}
