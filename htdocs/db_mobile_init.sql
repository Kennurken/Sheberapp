-- ============================================================
-- Sheber.kz — Mobile App Database Schema
-- Run this once on a fresh MySQL database.
-- Safe to re-run (uses IF NOT EXISTS / IF column exists).
-- ============================================================

SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- ──────────────────────────────────────────────────────────────
-- 1. USERS
-- Core table shared by both the website and mobile app.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100)  NOT NULL DEFAULT '',
  email         VARCHAR(180)  NULL     DEFAULT NULL,
  password_hash VARCHAR(255)  NULL     DEFAULT NULL,
  phone         VARCHAR(32)   NULL     DEFAULT NULL,
  role          ENUM('client','master') NOT NULL DEFAULT 'client',
  city          VARCHAR(120)  NULL     DEFAULT NULL,
  bio           TEXT          NULL,
  profession    VARCHAR(200)  NULL     DEFAULT NULL,
  profession_category_id INT NULL DEFAULT NULL,
  experience    TINYINT       NULL     DEFAULT 0,
  balance       DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  is_blocked    TINYINT(1)    NOT NULL DEFAULT 0,
  is_online     TINYINT(1)    NOT NULL DEFAULT 0,
  is_subscribed TINYINT(1)    NOT NULL DEFAULT 0,
  avatar_url    VARCHAR(512)  NULL     DEFAULT NULL,
  avatar_color  VARCHAR(20)   NOT NULL DEFAULT '#1cb7ff',
  last_seen     DATETIME      NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

  UNIQUE KEY uq_email (email),
  UNIQUE KEY uq_phone (phone),
  KEY idx_role_city (role, city),
  KEY idx_last_seen (last_seen)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Уже существующие БД (старый init без колонок) — MariaDB 10.3+ / MySQL 8.0.29+
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NULL AFTER email;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profession_category_id INT NULL DEFAULT NULL;

-- ──────────────────────────────────────────────────────────────
-- 2. MOBILE OTP CODES
-- Phone-based OTP authentication for the mobile app.
-- Replaces SMS service — codes stored here and sent later.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS mobile_otp (
  id         INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
  phone      VARCHAR(32) NOT NULL,
  code       CHAR(6)     NOT NULL,
  attempts   TINYINT     NOT NULL DEFAULT 0,
  verified   TINYINT(1)  NOT NULL DEFAULT 0,
  created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME    NOT NULL,

  KEY idx_phone_code (phone, code),
  KEY idx_expires    (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────────────────────────────
-- 3. SERVICE CATEGORIES
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS master_categories (
  id         INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(120) NOT NULL,
  icon       VARCHAR(80)  NULL,
  sort_order INT          NOT NULL DEFAULT 0,

  KEY idx_sort (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed default categories (insert only if table is empty)
INSERT INTO master_categories (name, icon, sort_order)
SELECT * FROM (
  SELECT 'Сантехника',  'plumbing',     1  UNION ALL
  SELECT 'Электрик',    'electric',     2  UNION ALL
  SELECT 'Жөндеу',      'repair',       3  UNION ALL
  SELECT 'Тазалық',     'cleaning',     4  UNION ALL
  SELECT 'Терезе',      'windows',      5  UNION ALL
  SELECT 'Бояу',        'painting',     6  UNION ALL
  SELECT 'Ағаш жұмысы', 'carpentry',   7  UNION ALL
  SELECT 'Басқа',       'other',        8
) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM master_categories LIMIT 1);

-- ──────────────────────────────────────────────────────────────
-- 4. ORDERS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id             INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
  client_id      INT           NULL,
  master_id      INT           NULL,
  category_id    INT           NULL,
  description    TEXT          NOT NULL,
  address        VARCHAR(255)  NOT NULL DEFAULT '',
  city           VARCHAR(120)  NOT NULL DEFAULT '',
  price          INT           NOT NULL DEFAULT 0,
  status         ENUM('new','in_progress','completed','cancelled') NOT NULL DEFAULT 'new',

  -- Guest order support (order without account)
  guest_name     VARCHAR(100)  NULL,
  guest_phone    VARCHAR(32)   NULL,
  is_guest_order TINYINT(1)    NOT NULL DEFAULT 0,

  -- Geo
  client_lat     DECIMAL(9,6)  NULL,
  client_lng     DECIMAL(9,6)  NULL,

  accepted_at    DATETIME      NULL,
  completed_at   DATETIME      NULL,
  created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  KEY idx_client   (client_id),
  KEY idx_master   (master_id),
  KEY idx_status   (status),
  KEY idx_city     (city),
  KEY idx_master_accepted (master_id, accepted_at),
  CONSTRAINT fk_order_client   FOREIGN KEY (client_id)   REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_order_master   FOREIGN KEY (master_id)   REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_order_category FOREIGN KEY (category_id) REFERENCES master_categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────────────────────────────
-- 5. ORDER MESSAGES (chat)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_messages (
  id         INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_id   INT          NOT NULL,
  sender_id  INT          NULL,
  message    TEXT         NOT NULL,
  is_system  TINYINT(1)   NOT NULL DEFAULT 0,
  is_read    TINYINT(1)   NOT NULL DEFAULT 0,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  KEY idx_order   (order_id),
  KEY idx_sender  (sender_id),
  CONSTRAINT fk_msg_order  FOREIGN KEY (order_id)  REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_msg_sender FOREIGN KEY (sender_id) REFERENCES users(id)  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────────────────────────────
-- 6. ORDER PHOTOS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_photos (
  id         INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_id   INT          NOT NULL,
  file_path  VARCHAR(255) NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  KEY idx_order_id (order_id),
  CONSTRAINT fk_photo_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────────────────────────────
-- 7. ORDER COMPLETION FLAGS
-- Both sides must mark "done" before order is completed.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_done (
  id       INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  done_by  ENUM('client','master') NOT NULL,
  user_id  INT NOT NULL,

  UNIQUE KEY uq_order_side (order_id, done_by),
  KEY idx_order (order_id),
  CONSTRAINT fk_done_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_done_user  FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────────────────────────────
-- 8. REVIEWS
-- Client reviews for masters after order completion.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
  id         INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
  master_id  INT          NOT NULL,
  client_id  INT          NOT NULL,
  order_id   INT          NULL,
  rating     TINYINT      NOT NULL DEFAULT 5,
  comment    TEXT         NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  KEY idx_master   (master_id),
  KEY idx_client   (client_id),
  KEY idx_order    (order_id),
  CONSTRAINT fk_review_master FOREIGN KEY (master_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_review_client FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_review_order  FOREIGN KEY (order_id)  REFERENCES orders(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────────────────────────────
-- 9. PUSH NOTIFICATION SUBSCRIPTIONS (mobile)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS push_subscriptions (
  id         INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id    INT          NOT NULL,
  token      VARCHAR(512) NOT NULL,
  platform   ENUM('android','ios','web') NOT NULL DEFAULT 'android',
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uq_user_token (user_id, token(191)),
  KEY idx_user (user_id),
  CONSTRAINT fk_push_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ──────────────────────────────────────────────────────────────
-- Done. Run this SQL in your MySQL client or phpMyAdmin.
-- ──────────────────────────────────────────────────────────────
