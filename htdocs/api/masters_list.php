<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');

$u = current_user($pdo);
$q     = trim((string)($_GET['q'] ?? ''));
$defaultCity = ($u !== null) ? trim((string)($u['city'] ?? '')) : '';
$allCities = isset($_GET['all_cities']) && (string)$_GET['all_cities'] === '1';
if ($allCities) {
  $city = '';
} elseif (array_key_exists('city', $_GET)) {
  $city = trim((string)$_GET['city']);
} else {
  $city = $defaultCity;
}
$catId     = max(0, (int)($_GET['category_id'] ?? 0));
$minRating = max(0.0, (float)($_GET['min_rating'] ?? 0));

$limit = (int)($_GET['limit'] ?? 20);
if ($limit < 1) {
    $limit = 20;
}
if ($limit > 100) {
    $limit = 100;
}
$offset = max(0, (int)($_GET['offset'] ?? 0));
if ($offset > 50000) {
    $offset = 50000;
}

$sql = "
  SELECT
    u.id,
    u.name,
    COALESCE(u.city, '') AS city,
    COALESCE(u.profession, '') AS profession,
    COALESCE(u.experience, 0) AS experience,
    COALESCE(u.bio, '') AS bio,
    COALESCE(u.phone, '') AS phone,
    COALESCE(u.avatar_url, '') AS avatar_url,
    COALESCE(u.avatar_color, '#1cb7ff') AS avatar_color,
    COALESCE(u.is_online, 0) AS is_online,
    (SELECT AVG(r.rating) FROM reviews r WHERE r.master_id = u.id) AS rating_avg,
    (SELECT COUNT(*) FROM reviews r WHERE r.master_id = u.id) AS rating_count,
    (SELECT COUNT(*) FROM orders o WHERE o.master_id = u.id AND o.status = 'completed') AS completed_count
  FROM users u
  WHERE u.role = 'master'
";

$params = [];

if ($q !== '') {
  $sql .= " AND (u.name LIKE ? OR COALESCE(u.profession,'') LIKE ? OR COALESCE(u.city,'') LIKE ?)";
  $params[] = '%' . $q . '%';
  $params[] = '%' . $q . '%';
  $params[] = '%' . $q . '%';
}

if ($city !== '') {
  // LIKE instead of exact match: "Левый" finds "Левый берег", "левый берег 35" etc.
  $sql .= " AND u.city LIKE ?";
  $params[] = '%' . $city . '%';
}

if ($catId > 0) {
  $sql .= " AND u.profession_category_id = ?";
  $params[] = $catId;
}

if ($minRating > 0) {
    $sql .= " HAVING rating_avg >= ?";
    $params[] = $minRating;
}

$sql .= " ORDER BY COALESCE(u.is_online, 0) DESC, rating_avg DESC, rating_count DESC, u.id DESC LIMIT ? OFFSET ?";
$params[] = $limit;
$params[] = $offset;

try {
  $st = $pdo->prepare($sql);
  $st->execute($params);
  $rows = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];

  foreach ($rows as &$r) {
    $r['experience'] = (int)($r['experience'] ?? 0);
    $r['is_online'] = (int)($r['is_online'] ?? 0);
    $r['rating_avg'] = $r['rating_avg'] !== null ? (float)$r['rating_avg'] : null;
    $r['rating_count']     = (int)($r['rating_count'] ?? 0);
    $r['completed_count']  = (int)($r['completed_count'] ?? 0);
  }
  unset($r);

  json_out(['ok' => true, 'data' => $rows]);
} catch (Throwable $e) {
  try {
    $fallbackSql = "
      SELECT
        id,
        name,
        COALESCE(city, '') AS city,
        '' AS profession,
        0 AS experience,
        '' AS bio,
        COALESCE(phone, '') AS phone,
        COALESCE(avatar_url, '') AS avatar_url,
        COALESCE(avatar_color, '#1cb7ff') AS avatar_color,
        0 AS is_online,
        NULL AS rating_avg,
        0 AS rating_count
      FROM users
      WHERE role = 'master'
    ";

    $fallbackParams = [];
    if ($city !== '') {
      $fallbackSql .= " AND city LIKE ?";
      $fallbackParams[] = '%' . $city . '%';
    }
    if ($q !== '') {
      $fallbackSql .= " AND (name LIKE ? OR COALESCE(city,'') LIKE ?)";
      $fallbackParams[] = '%' . $q . '%';
      $fallbackParams[] = '%' . $q . '%';
    }

    $fallbackSql .= " ORDER BY id DESC LIMIT ? OFFSET ?";
    $fallbackParams[] = $limit;
    $fallbackParams[] = $offset;

    $st = $pdo->prepare($fallbackSql);
    $st->execute($fallbackParams);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC) ?: [];
    json_out(['ok' => true, 'data' => $rows]);
  } catch (Throwable $e2) {
    json_out(['ok' => false, 'error' => 'db_error'], 500);
  }
}
