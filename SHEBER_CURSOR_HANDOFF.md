# Handoff для следующего агента Cursor (SHEBER.KZ)

**Одной строкой в новый чат:** Продолжай SHEBER в `c:\app\app\app`: прод `https://sheberkz.duckdns.org`, VPS `/var/www/sheber`, Nginx+PHP 8.1, БД `dbSheberkz`, деплой `deploy/sync-htdocs.ps1`, секреты только на сервере; полный контекст — этот файл.

---

## Проект и пути

- **Flutter:** `c:\app\app\app\sheber_app\`
- **PHP API:** `c:\app\app\app\htdocs\`
- **Деплой-скрипты:** `c:\app\app\app\deploy\`
- **Продакшен URL:** `https://sheberkz.duckdns.org`
- **База в приложении:** `sheber_app/lib/config/app_config.dart` → `kProdBaseUrl = 'https://sheberkz.duckdns.org'`
- **Абсолютные URL загрузок:** `sheber_app/lib/utils/upload_url.dart` (тот же хост)

## Паттерны приложения

- Локализация: `lib/l10n/app_strings.dart` → `S.lang(appState.language)` + Provider
- Тёмная тема: `AppState.darkMode`
- API: `ApiClient` singleton, cookies, CSRF
- Пуши: `lib/app_navigator.dart` (`rootNavigatorKey`), `lib/services/push_open_order.dart` (`pushOrderOpenError`, язык из AppState)

## Feature flags

`sheber_app/lib/config/feature_flags.dart` — например `kShowPremiumHomeBanner = false` (Premium в карусели на главной скрыт). Подписки/Kaspi в прод не продвигать без согласования с заказчиком.

## VPS (фактическая конфигурация)

- **IP:** 185.98.7.61, Ubuntu 22.04, hostname `server`
- **Web root для DuckDNS:** `/var/www/sheber` (содержимое локального `htdocs` сюда)
- **Стек:** **Nginx** + **PHP 8.1-FPM** + **MariaDB**
- Раньше порт 80 занимал **Apache** — для Nginx: `systemctl stop apache2 && systemctl disable apache2`, затем `systemctl start nginx`
- **HTTPS:** Let’s Encrypt / `certbot --nginx -d sheberkz.duckdns.org`
- **DNS:** DuckDNS A → 185.98.7.61

### Nginx + PHP (критично)

Шаблон Ubuntu `snippets/fastcgi-php.conf` с `fastcgi_split_path_info` даёт **404** на URI без хвоста после `.php` (например `/api/ping.php`). В `location ~ \.php$` использовать:

- `try_files $uri =404;`
- `include fastcgi_params;`
- `fastcgi_param SCRIPT_FILENAME $document_root$uri;`
- `fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;`

Эталон в репо: `deploy/nginx-sheberkz.duckdns.org.conf`. После **certbot** проверить, что блок PHP не откатился к `snippets/fastcgi-php.conf`.

### Деплой с Windows

- Ключ SSH (пример): `C:\Users\user\.ssh\id_ed25519_sheber`
- Подготовка ключа: `deploy/prepare-ssh-from-windows.ps1`
- Синхронизация кода: `.\deploy\sync-htdocs.ps1 -IdentityFile "C:\Users\user\.ssh\id_ed25519_sheber"`
- Скрипт **не** заливает `htdocs/config.local.php` (только на VPS вручную)
- Шаблон секретов: `htdocs/config.local.example.php`
- Первичная настройка сервера (пакеты, vhost, каталоги): `deploy/server-bootstrap-ubuntu.sh`

### База данных

- База: **`dbSheberkz`**
- Пользователь приложения: **`rootSheber`** (пароль в `/var/www/sheber/config.local.php`)
- Схема: импорт **`/var/www/sheber/db_mobile_init.sql`**
- В **`db_mobile_init.sql`** в репозитории добавлены **`password_hash`** и **`profession_category_id`** для `users` + `ALTER ... IF NOT EXISTS` для уже существующих БД — без **`password_hash`** регистрация по email (`email_auth.php`) даёт **500**
- Админские SQL удобно выполнять: `sudo mysql dbSheberkz` (без пароля приложения)

### API / проверки

- `api/ping.php` **без сессии** → `{"ok":false,"error":"not_logged_in"}` — **нормально**
- Проверка «сервер жив»: `curl https://sheberkz.duckdns.org/api/csrf.php` → JSON с токеном
- **CORS:** в `htdocs/api/_boot.php` уже есть `https://sheberkz.duckdns.org`

## Другие web-корни на сервере

Также могут существовать `/var/www/html`, `/var/www/sheber_v2` — для DuckDNS важен тот, что в `server_name sheberkz.duckdns.org` в `sites-enabled`. В `/root` могут лежать архивы/SQL — не путать с document root.

## Недавние правки Flutter (сессия)

- `lib/l10n/app_strings.dart` — `invalidEmailFormat`
- `lib/screens/tabs/tab_profile.dart` — маппинг `invalid_email`, `db_error`, `server_error`; лог регистрации только в `kDebugMode`
- `lib/screens/order_chat_screen.dart` — отладочные логи чата только в `kDebugMode`

## Ранее в проекте (долгосрочный контекст)

Геокод Nominatim, client_lat/lng в заказах и картах, master_map_sheet, master_profile / портфолио, правки `orders_feed` (исключение своих заказов мастером), `messages_list` с автомиграцией колонок, и т.д. — см. `CLAUDE.md`.

## Документация

- Общий контекст проекта: `CLAUDE.md` (стек, API, **статус багов**, бэклог, `flutter analyze`, деплой)
- Этот handoff: `SHEBER_CURSOR_HANDOFF.md`
