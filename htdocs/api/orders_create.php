<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('POST');
rate_limit('orders_create', 10, 300);
$user = require_login($pdo);
require_role($user, 'client');

$serviceTitle = get_str('service_title', 120);
$description  = get_str('description', 2000);
$address      = get_str('address', 255);
$city         = get_str('city', 120, (string)($user['city'] ?? ''));
$guestName    = get_str('guest_name', 100, (string)($user['name'] ?? ''));
$guestPhone   = get_str('guest_phone', 32, (string)($user['phone'] ?? ''));
$latRaw       = get_str('client_lat', 32);
$lngRaw       = get_str('client_lng', 32);
$price        = get_int('price', 0);
$masterId     = get_int('master_id', 0);

if ($serviceTitle === '' || $description === '' || $address === '') {
  json_out(['ok' => false, 'error' => 'validation'], 422);
}

// Phone is optional for email-only users
if ($guestPhone !== '') {
  $phoneNorm = preg_replace('/\D+/', '', $guestPhone);
  if (!preg_match('/^(7|8)?\d{10}$/', $phoneNorm)) {
    json_out(['ok' => false, 'error' => 'phone_invalid'], 422);
  }
}

// Use 'Не указан' if city is empty
if ($city === '') $city = 'Не указан';

if ($price < 0 || $price > 5000000) {
  json_out(['ok' => false, 'error' => 'bad_price'], 422);
}

$assignedMaster = null;
if ($masterId > 0) {
  try {
    $st = $pdo->prepare("SELECT id, name, role, COALESCE(city,'') AS city FROM users WHERE id = ? LIMIT 1");
    $st->execute([$masterId]);
    $assignedMaster = $st->fetch(PDO::FETCH_ASSOC) ?: null;
  } catch (Throwable $e) {
    $assignedMaster = null;
  }
  if (!$assignedMaster || (string)($assignedMaster['role'] ?? '') !== 'master') {
    json_out(['ok' => false, 'error' => 'master_not_found'], 404);
  }
  if ($city === '' && !empty($assignedMaster['city'])) {
    $city = (string)$assignedMaster['city'];
  }
}

$lat = is_numeric($latRaw) ? (float)$latRaw : null;
$lng = is_numeric($lngRaw) ? (float)$lngRaw : null;

// Use category_id sent directly from Flutter (reliable, matches kAppCategories IDs)
$categoryId = get_int('category_id', 0);
if ($categoryId <= 0) {
  // Fallback: look up by name in master_categories table
  $categoryId = 1;
  try {
    $st = $pdo->prepare("SELECT id FROM master_categories WHERE LOWER(name)=LOWER(?) LIMIT 1");
    $st->execute([$serviceTitle]);
    $row = $st->fetch();
    if ($row && isset($row['id'])) {
      $categoryId = (int)$row['id'];
    }
  } catch (Throwable $e) {}
}

// DDL must be OUTSIDE transaction (MySQL auto-commits DDL which breaks the transaction)
try {
  $pdo->exec("CREATE TABLE IF NOT EXISTS order_photos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_order_id (order_id)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
} catch (Throwable $e) {}

try {
  $pdo->beginTransaction();

  $inserted = false;
  $orderId = 0;
  $variants = [];

  if ($masterId > 0) {
    $variants[] = [
      "INSERT INTO orders (client_id, master_id, category_id, description, address, price, status, created_at, updated_at, city, guest_name, guest_phone, is_guest_order, client_lat, client_lng) VALUES (?, ?, ?, ?, ?, ?, 'new', NOW(), NOW(), ?, ?, ?, 0, ?, ?)",
      [(int)$user['id'], $masterId, $categoryId, $description, $address, $price, $city, $guestName, $guestPhone, $lat, $lng]
    ];
    $variants[] = [
      "INSERT INTO orders (client_id, master_id, category_id, description, address, price, status, created_at, updated_at, city, guest_name, guest_phone, is_guest_order) VALUES (?, ?, ?, ?, ?, ?, 'new', NOW(), NOW(), ?, ?, ?, 0)",
      [(int)$user['id'], $masterId, $categoryId, $description, $address, $price, $city, $guestName, $guestPhone]
    ];
    $variants[] = [
      "INSERT INTO orders (client_id, master_id, category_id, description, address, price, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, 'new', NOW(), NOW())",
      [(int)$user['id'], $masterId, $categoryId, $description, $address, $price]
    ];
  } else {
    $variants[] = [
      "INSERT INTO orders (client_id, category_id, description, address, price, status, created_at, updated_at, city, guest_name, guest_phone, is_guest_order, client_lat, client_lng) VALUES (?, ?, ?, ?, ?, 'new', NOW(), NOW(), ?, ?, ?, 0, ?, ?)",
      [(int)$user['id'], $categoryId, $description, $address, $price, $city, $guestName, $guestPhone, $lat, $lng]
    ];
    $variants[] = [
      "INSERT INTO orders (client_id, category_id, description, address, price, status, created_at, updated_at, city, guest_name, guest_phone, is_guest_order) VALUES (?, ?, ?, ?, ?, 'new', NOW(), NOW(), ?, ?, ?, 0)",
      [(int)$user['id'], $categoryId, $description, $address, $price, $city, $guestName, $guestPhone]
    ];
    $variants[] = [
      "INSERT INTO orders (client_id, category_id, description, address, price, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 'new', NOW(), NOW())",
      [(int)$user['id'], $categoryId, $description, $address, $price]
    ];
  }

  foreach ($variants as [$sql, $params]) {
    try {
      $st = $pdo->prepare($sql);
      $st->execute($params);
      $orderId = (int)$pdo->lastInsertId();
      if ($orderId > 0) {
        $inserted = true;
        break;
      }
    } catch (Throwable $e) {}
  }

  if (!$inserted || $orderId <= 0) {
    throw new RuntimeException('order_insert_failed');
  }

  $sysText = "Заказ: {$serviceTitle}\nИмя: {$guestName}\nТелефон: {$guestPhone}\nГород: {$city}\nАдрес: {$address}";
  if ($masterId > 0 && $assignedMaster) {
    $sysText .= "\nНазначенный мастер: " . (string)($assignedMaster['name'] ?? ('#' . $masterId));
  }

  $msgVariants = [
    ["INSERT INTO order_messages (order_id, sender_id, message, is_system, created_at) VALUES (?, ?, ?, 1, NOW())", [$orderId, (int)$user['id'], $sysText]],
    ["INSERT INTO order_messages (order_id, sender_id, message, created_at) VALUES (?, ?, ?, NOW())", [$orderId, (int)$user['id'], $sysText]],
    ["INSERT INTO order_messages (order_id, message, is_system, created_at) VALUES (?, ?, 1, NOW())", [$orderId, $sysText]],
    ["INSERT INTO order_messages (order_id, message, created_at) VALUES (?, ?, NOW())", [$orderId, $sysText]],
  ];
  foreach ($msgVariants as [$msgSql, $msgParams]) {
    try {
      $st = $pdo->prepare($msgSql);
      $st->execute($msgParams);
      break;
    } catch (Throwable $e) {}
  }

  try {
    if (!empty($_FILES['photos']) && is_array($_FILES['photos']['name'])) {
      $uploadDir = realpath(__DIR__ . '/..') . '/uploads/orders';
      if (!is_dir($uploadDir)) @mkdir($uploadDir, 0775, true);
      $names = $_FILES['photos']['name'];
      $tmp = $_FILES['photos']['tmp_name'];
      $err = $_FILES['photos']['error'];
      $size = $_FILES['photos']['size'];
      $max = min(3, count($names));
      for ($i = 0; $i < $max; $i++) {
        if (!isset($err[$i]) || (int)$err[$i] !== UPLOAD_ERR_OK) continue;
        if (!isset($tmp[$i]) || !is_uploaded_file($tmp[$i])) continue;
        if (isset($size[$i]) && (int)$size[$i] > 5 * 1024 * 1024) continue;
        $mime = upload_mime_type((string)$tmp[$i]);
        $ext = $mime === 'image/jpeg' ? 'jpg' : ($mime === 'image/png' ? 'png' : ($mime === 'image/webp' ? 'webp' : ''));
        if ($ext === '') continue;
        $fileName = 'order_' . $orderId . '_' . time() . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
        $destAbs = $uploadDir . '/' . $fileName;
        if (@move_uploaded_file($tmp[$i], $destAbs)) {
          $rel = 'uploads/orders/' . $fileName;
          $stp = $pdo->prepare("INSERT INTO order_photos (order_id, file_path, created_at) VALUES (?, ?, NOW())");
          $stp->execute([$orderId, $rel]);
        }
      }
    }
  } catch (Throwable $e) {}

  $pdo->commit();

  // Notify masters in this city/category about the new order
  try { @include_once __DIR__ . '/push_send.php'; } catch (Throwable $_e) {}
  try {
    $masterQuery = "SELECT id FROM users WHERE role = 'master' AND id != ?";
    $masterParams = [(int)$user['id']];
    if ($city !== '' && $city !== 'Не указан') {
      $masterQuery .= " AND city LIKE ? ESCAPE '\\\\'";
      $cityEsc = str_replace(['\\', '%', '_'], ['\\\\', '\\%', '\\_'], $city);
      $masterParams[] = '%' . $cityEsc . '%';
    }
    $masterQuery .= " LIMIT 50";
    $stM = $pdo->prepare($masterQuery);
    $stM->execute($masterParams);
    $masterIds = array_column($stM->fetchAll(PDO::FETCH_ASSOC), 'id');
    if (!empty($masterIds) && function_exists('push_notify_users')) {
      $pushTitle = 'Новый заказ: ' . mb_substr($serviceTitle, 0, 40);
      $pushBody  = mb_strlen($description) > 80
        ? mb_substr($description, 0, 77) . '...'
        : $description;
      push_notify_users($pdo, $masterIds, $pushTitle, $pushBody, [
        'type'     => 'new_order',
        'order_id' => (string)$orderId,
      ]);
    }
  } catch (Throwable $e) {
    error_log('[orders_create] push error: ' . $e->getMessage());
  }

  json_out(['ok' => true, 'data' => ['order_id' => $orderId]]);
} catch (Throwable $e) {
  if ($pdo->inTransaction()) $pdo->rollBack();
  error_log('[ORDERS CREATE] ' . $e->getMessage());
  json_out(['ok' => false, 'error' => 'db_error'], 500);
}