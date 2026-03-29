<?php
declare(strict_types=1);

/**
 * Скопируйте в config.local.php на сервере (и локально) и заполните значения.
 * Файл config.local.php не должен попадать в git / в архивы для третьих лиц.
 *
 * На VPS с MySQL на той же машине обычно достаточно:
 *   DB_HOST = '127.0.0.1' или 'localhost' (init.php подхватит unix_socket)
 */
return [
  'DB_HOST'   => '127.0.0.1',
  'DB_PORT'   => 3306,
  'DB_NAME'   => 'sheber',
  'DB_USER'   => 'sheber_user',
  'DB_PASS'   => 'CHANGE_ME',
  // Раскомментируйте, если используете сокет явно:
  // 'DB_SOCKET' => '/var/run/mysqld/mysqld.sock',

  /** Пароль входа в /admin/ */
  'ADMIN_PASSWORD' => 'CHANGE_ME_LONG_RANDOM',

  /** Путь к JSON ключу Firebase для FCM V1 (на сервере, вне web-root). */
  'FCM_SERVICE_ACCOUNT_PATH' => '/etc/sheber/firebase-adminsdk.json',

  /**
   * Telegram: токен бота @BotFather и chat_id куда слать обращения из приложения (support_send.php).
   * chat_id: число (личка, группа, супергруппа вида -100…) или @username супергруппы/канала.
   * Бот должен быть в группе / состоять в канале; иначе API вернёт "chat not found".
   */
  'TELEGRAM_BOT_TOKEN' => '',
  'TELEGRAM_SUPPORT_CHAT_ID' => '',
];
