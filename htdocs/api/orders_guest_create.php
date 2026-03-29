<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('orders_guest_create', 8, 600);

$guestName    = get_str('guest_name', 100);
$guestPhone   = get_str('guest_phone', 32);
$city         = get_str('city', 120);
$serviceTitle = get_str('service_title', 120);
$description  = get_str('description', 2000);
$address      = get_str('address', 255);
$consent      = get_int('consent_contacts', 0);
$latRaw       = get_str('client_lat', 32);
$lngRaw       = get_str('client_lng', 32);

if ($guestName === '' || $guestPhone === '' || $city === '' || $serviceTitle === '' || $description === '' || $address === '' || $consent !== 1) {
  json_out(['ok' => false, 'error' => 'validation'], 422);
}

$phoneNorm = preg_replace('/\D+/', '', $guestPhone);
if (!preg_match('/^(7|8)?\d{10}$/', $phoneNorm)) {
  json_out(['ok' => false, 'error' => 'phone_invalid'], 422);
}

$lat = is_numeric($latRaw) ? (float)$latRaw : null;
$lng = is_numeric($lngRaw) ? (float)$lngRaw : null;
$categoryId = 1;

try {
  $st = $pdo->prepare("SELECT id FROM master_categories WHERE LOWER(name)=LOWER(?) LIMIT 1");
  $st->execute([$serviceTitle]);
  $row = $st->fetch(PDO::FETCH_ASSOC);
  if ($row && isset($row['id'])) {
    $categoryId = (int)$row['id'];
  }
} catch (Throwable $e) {
  error_log('[ORDERS GUEST CREATE] category lookup skipped: ' . $e->getMessage());
}

$orderId = 0;

try {
  $pdo->beginTransaction();

  $inserted = false;
  $variants = [
    [
      "INSERT INTO orders (client_id, category_id, description, address, price, status, created_at, updated_at, city, guest_name, guest_phone, is_guest_order, client_lat, client_lng) VALUES (NULL, ?, ?, ?, 0, 'new', NOW(), NOW(), ?, ?, ?, 1, ?, ?)",
      [$categoryId, $description, $address, $city, $guestName, $guestPhone, $lat, $lng],
    ],
    [
      "INSERT INTO orders (client_id, category_id, description, address, price, status, created_at, updated_at, city, guest_name, guest_phone, is_guest_order) VALUES (NULL, ?, ?, ?, 0, 'new', NOW(), NOW(), ?, ?, ?, 1)",
      [$categoryId, $description, $address, $city, $guestName, $guestPhone],
    ],
    [
      "INSERT INTO orders (client_id, category_id, description, address, price, status, created_at, updated_at) VALUES (NULL, ?, ?, ?, 0, 'new', NOW(), NOW())",
      [$categoryId, $description, $address],
    ],
  ];

  foreach ($variants as [$sql, $params]) {
    try {
      $st = $pdo->prepare($sql);
      $st->execute($params);
      $orderId = (int)$pdo->lastInsertId();
      $inserted = $orderId > 0;
      if ($inserted) break;
    } catch (Throwable $e) {
      error_log('[ORDERS GUEST CREATE] insert variant failed: ' . $e->getMessage());
    }
  }

  if (!$inserted || $orderId <= 0) {
    throw new RuntimeException('order_insert_failed');
  }

  $pdo->commit();
} catch (Throwable $e) {
  if ($pdo->inTransaction()) $pdo->rollBack();
  error_log('[ORDERS GUEST CREATE] ' . $e->getMessage());
  json_out(['ok' => false, 'error' => 'db_error'], 500);
}

// Best-effort system message. It must never rollback the created order.
try {
  $sysText = "Заказ: {$serviceTitle}\nИмя: {$guestName}\nТелефон: {$guestPhone}\nГород: {$city}\nАдрес: {$address}";
  $msgVariants = [
    ["INSERT INTO order_messages (order_id, sender_id, message, is_system, created_at) VALUES (?, 0, ?, 1, NOW())", [$orderId, $sysText]],
    ["INSERT INTO order_messages (order_id, sender_id, message, is_system, created_at) VALUES (?, NULL, ?, 1, NOW())", [$orderId, $sysText]],
    ["INSERT INTO order_messages (order_id, message, is_system, created_at) VALUES (?, ?, 1, NOW())", [$orderId, $sysText]],
  ];
  foreach ($msgVariants as [$sql, $params]) {
    try {
      $st = $pdo->prepare($sql);
      $st->execute($params);
      break;
    } catch (Throwable $e) {
      error_log('[ORDERS GUEST CREATE] system message skipped: ' . $e->getMessage());
    }
  }
} catch (Throwable $e) {
  error_log('[ORDERS GUEST CREATE] system message outer skip: ' . $e->getMessage());
}

// Best-effort photo upload.
try {
  $pdo->exec("CREATE TABLE IF NOT EXISTS order_photos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_order_id (order_id)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
} catch (Throwable $e) {
  error_log('[ORDERS GUEST CREATE] order_photos ensure skipped: ' . $e->getMessage());
}

try {
  $files = $_FILES['photos'] ?? null;
  if ($files && !empty($files['name']) && is_array($files['name'])) {
    $uploadDir = realpath(__DIR__ . '/..') . '/uploads/orders';
    if ($uploadDir === false) {
      $uploadDir = dirname(__DIR__) . '/uploads/orders';
    }
    if (!is_dir($uploadDir)) {
      @mkdir($uploadDir, 0775, true);
    }

    $names = $files['name'];
    $tmp   = $files['tmp_name'];
    $err   = $files['error'];
    $size  = $files['size'];
    $max   = min(3, count($names));

    for ($i = 0; $i < $max; $i++) {
      if (!isset($err[$i]) || (int)$err[$i] !== UPLOAD_ERR_OK) continue;
      if (!isset($tmp[$i]) || !is_uploaded_file($tmp[$i])) continue;
      if (isset($size[$i]) && (int)$size[$i] > 5 * 1024 * 1024) continue;

      $mime = upload_mime_type((string)$tmp[$i]);
      $ext = match ($mime) {
        'image/jpeg' => 'jpg',
        'image/png'  => 'png',
        'image/webp' => 'webp',
        default      => '',
      };
      if ($ext === '') continue;

      $fileName = 'order_' . $orderId . '_' . time() . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
      $destAbs  = rtrim($uploadDir, '/\\') . '/' . $fileName;
      if (@move_uploaded_file($tmp[$i], $destAbs)) {
        $rel = 'uploads/orders/' . $fileName;
        try {
          $stp = $pdo->prepare("INSERT INTO order_photos (order_id, file_path, created_at) VALUES (?, ?, NOW())");
          $stp->execute([$orderId, $rel]);
        } catch (Throwable $e) {
          error_log('[ORDERS GUEST CREATE] photo db save skipped: ' . $e->getMessage());
        }
      }
    }
  }
} catch (Throwable $e) {
  error_log('[ORDERS GUEST CREATE] photo upload skipped: ' . $e->getMessage());
}

json_out(['ok' => true, 'data' => ['order_id' => $orderId]]);
