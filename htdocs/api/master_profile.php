<?php
declare(strict_types=1);
require __DIR__ . '/_boot.php';

require_method('GET');
$user = require_login($pdo);

$masterId = get_int('master_id', 0);
if ($masterId <= 0) {
    json_out(['ok' => false, 'error' => 'validation'], 422);
}

// Ensure columns exist
try { $pdo->exec("ALTER TABLE users ADD COLUMN bio TEXT DEFAULT NULL"); } catch (Throwable $e) {}
try { $pdo->exec("ALTER TABLE users ADD COLUMN experience INT DEFAULT 0"); } catch (Throwable $e) {}
try { $pdo->exec("ALTER TABLE users ADD COLUMN is_verified TINYINT(1) DEFAULT 0"); } catch (Throwable $e) {}

try {
    $st = $pdo->prepare("
        SELECT u.id, u.name, u.phone, u.city, u.profession,
               COALESCE(u.bio, '') AS bio,
               COALESCE(u.experience, 0) AS experience,
               COALESCE(u.avatar_url, '') AS avatar_url,
               COALESCE(u.avatar_color, '#1cb7ff') AS avatar_color,
               COALESCE(u.is_verified, 0) AS is_verified,
               u.created_at AS member_since,
               (SELECT COUNT(*) FROM orders o WHERE o.master_id = u.id AND o.status = 'completed') AS completed_orders,
               (SELECT COALESCE(AVG(r.rating), 0) FROM reviews r WHERE r.master_id = u.id) AS avg_rating,
               (SELECT COUNT(*) FROM reviews r WHERE r.master_id = u.id) AS review_count
        FROM users u
        WHERE u.id = ? AND u.role = 'master'
        LIMIT 1
    ");
    $st->execute([$masterId]);
    $master = $st->fetch(PDO::FETCH_ASSOC);

    if (!$master) {
        json_out(['ok' => false, 'error' => 'not_found'], 404);
    }

    // Portfolio: same storage as mobile `portfolio_photos.php`; fallback legacy `master_portfolio`
    $portfolio = [];
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS portfolio_photos (
                id          INT AUTO_INCREMENT PRIMARY KEY,
                master_id   INT NOT NULL,
                file_path   VARCHAR(512) NOT NULL,
                caption     VARCHAR(255) NOT NULL DEFAULT '',
                created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_master (master_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ");
        $st2 = $pdo->prepare('SELECT id, file_path, caption, created_at FROM portfolio_photos WHERE master_id = ? ORDER BY id DESC LIMIT 20');
        $st2->execute([$masterId]);
        $rows = $st2->fetchAll(PDO::FETCH_ASSOC) ?: [];
        foreach ($rows as $r) {
            $path = '/' . ltrim((string)$r['file_path'], '/');
            $cap = (string)$r['caption'];
            $portfolio[] = [
                'id'          => (int)$r['id'],
                'url'         => $path,
                'caption'     => $cap,
                'photo_url'   => $path,
                'description' => $cap,
            ];
        }
    } catch (Throwable $e) {}

    if ($portfolio === []) {
        try {
            $pdo->exec("CREATE TABLE IF NOT EXISTS master_portfolio (
                id INT AUTO_INCREMENT PRIMARY KEY,
                master_id INT NOT NULL,
                photo_url VARCHAR(255) NOT NULL,
                description VARCHAR(500) DEFAULT '',
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                KEY idx_master (master_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
            $st2 = $pdo->prepare("SELECT id, photo_url, description, created_at FROM master_portfolio WHERE master_id = ? ORDER BY created_at DESC LIMIT 20");
            $st2->execute([$masterId]);
            $legacy = $st2->fetchAll(PDO::FETCH_ASSOC) ?: [];
            foreach ($legacy as $r) {
                $path = '/' . ltrim((string)$r['photo_url'], '/');
                $desc = (string)($r['description'] ?? '');
                $portfolio[] = [
                    'id'          => (int)$r['id'],
                    'url'         => $path,
                    'caption'     => $desc,
                    'photo_url'   => $path,
                    'description' => $desc,
                ];
            }
        } catch (Throwable $e) {}
    }

    // Get recent reviews
    $reviews = [];
    try {
        $st3 = $pdo->prepare("
            SELECT r.id, r.rating, r.comment, r.created_at,
                   COALESCE(c.name, 'Клиент') AS client_name,
                   COALESCE(NULLIF(c.avatar_url, ''), '') AS client_avatar_url,
                   COALESCE(c.avatar_color, '#1cb7ff') AS client_avatar_color
            FROM reviews r
            LEFT JOIN users c ON c.id = r.client_id
            WHERE r.master_id = ?
            ORDER BY r.created_at DESC
            LIMIT 10
        ");
        $st3->execute([$masterId]);
        $reviews = $st3->fetchAll(PDO::FETCH_ASSOC) ?: [];
    } catch (Throwable $e) {}

    // Get work history (completed orders)
    $workHistory = [];
    try {
        $st4 = $pdo->prepare("
            SELECT o.id, o.description, o.address, o.price, o.completed_at,
                   COALESCE(mc.name, 'Тапсырыс') AS service_title
            FROM orders o
            LEFT JOIN master_categories mc ON mc.id = o.category_id
            WHERE o.master_id = ? AND o.status = 'completed'
            ORDER BY o.completed_at DESC
            LIMIT 10
        ");
        $st4->execute([$masterId]);
        $workHistory = $st4->fetchAll(PDO::FETCH_ASSOC) ?: [];
    } catch (Throwable $e) {}

    // Only show phone if requesting user has active/completed order with this master
    $showPhone = false;
    try {
        $stP = $pdo->prepare("SELECT id FROM orders WHERE master_id = ? AND client_id = ? AND status IN ('in_progress','completed') LIMIT 1");
        $stP->execute([$masterId, (int)$user['id']]);
        $showPhone = (bool)$stP->fetch();
    } catch (Throwable $e) {}

    json_out(['ok' => true, 'data' => [
        'id'               => (int)$master['id'],
        'name'             => $master['name'],
        'phone'            => $showPhone ? $master['phone'] : null,
        'city'             => $master['city'],
        'profession'       => $master['profession'],
        'bio'              => $master['bio'],
        'experience'       => (int)$master['experience'],
        'avatar_url'       => $master['avatar_url'],
        'avatar_color'     => $master['avatar_color'],
        'is_verified'      => (int)$master['is_verified'] === 1,
        'member_since'     => $master['member_since'],
        'completed_orders' => (int)$master['completed_orders'],
        'avg_rating'       => round((float)$master['avg_rating'], 1),
        'review_count'     => (int)$master['review_count'],
        'portfolio'        => $portfolio,
        'reviews'          => $reviews,
        'work_history'     => $workHistory,
    ]]);
} catch (Throwable $e) {
    error_log('[master_profile] ' . $e->getMessage());
    json_out(['ok' => false, 'error' => 'db_error'], 500);
}
