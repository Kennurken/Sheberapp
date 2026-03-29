-- Sheber.kz Day 3-6 migrations

-- 1) Users: block + online
ALTER TABLE users ADD COLUMN is_blocked TINYINT(1) NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN last_seen DATETIME NULL;

-- 2) Orders: ensure accepted_at exists (for strict daily limit)
ALTER TABLE orders ADD COLUMN accepted_at DATETIME NULL;
ALTER TABLE orders ADD INDEX idx_orders_master_accepted (master_id, accepted_at);

-- 3) Complaints
CREATE TABLE complaints (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  from_user_id INT NOT NULL,
  against_user_id INT NOT NULL,
  reason VARCHAR(120) NOT NULL,
  body TEXT NOT NULL,
  status ENUM('open','resolved') NOT NULL DEFAULT 'open',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_order (order_id),
  KEY idx_status (status),
  KEY idx_against (against_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
