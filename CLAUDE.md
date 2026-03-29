# SHEBER.KZ — Claude Project Context

## Проект
**SHEBER.KZ** — маркетплейс мастеров (сантехники, электрики, уборка и т.д.) для Казахстана.
- Клиент создаёт заказ → Мастера делают ставки → Клиент выбирает → Работа выполнена → Отзыв

---

## Стек

| Слой | Технология |
|------|-----------|
| Мобильное приложение | Flutter (Dart), SDK ^3.11 |
| Бэкенд | PHP 8+ (процедурный стиль), `htdocs/api/_boot.php` |
| База данных | MariaDB/MySQL (прод: VPS `dbSheberkz`; возможен legacy Beget) |
| Хостинг (прод API) | **https://sheberkz.duckdns.org** — VPS, Nginx + PHP 8.1-FPM, document root `/var/www/sheber` |
| Legacy | kmaruk4u.beget.tech — старый хостинг в доках/URL загрузок (см. `upload_url.dart`) |
| Push-уведомления | Firebase FCM V1 |
| Карты/Адреса | Yandex Maps API (bbox: Казахстан), геокодинг в приложении |
| SMS | usta-auth.vercel.app (прокси) |
| Поддержка | Telegram бот @KenHunterBot |
| HTTP-клиент Flutter | Dio + CookieJar |
| State management | Provider (ChangeNotifier) |
| Деплой PHP с Windows | `deploy/sync-htdocs.ps1` (не затирает `config.local.php` на сервере) |

---

## Структура файлов

```
C:\app\app\app\
├── CLAUDE.md                    ← этот файл
├── SHEBER_CURSOR_HANDOFF.md     ← прод VPS, Nginx+PHP, деплой, проверки API
├── SHEBER_CONTEXT.md            ← подробная документация
├── deploy/                      ← sync-htdocs.ps1, nginx-sheberkz.duckdns.org.conf, bootstrap
├── google-services.json         ← Firebase конфиг (не трогать)
├── htdocs/                      ← PHP бэкенд (основной)
│   ├── init.php                 ← PDO, CSRF, current_user(), subscription_sync()
│   ├── api/_boot.php            ← JSON, CORS, rate limiter, require_login()
│   ├── config.local.php         ← только локально / на VPS (не коммитить!)
│   ├── config.local.example.php ← шаблон секретов
│   ├── lang.php                 ← переводы KZ/RU (веб)
│   └── api/                     ← эндпоинты REST
└── sheber_app/
    └── lib/
        ├── main.dart              ← точка входа
        ├── config/app_config.dart ← kProdBaseUrl
        ├── config/feature_flags.dart
        ├── utils/upload_url.dart  ← абсолютные URL вложений
        ├── api/api_client.dart    ← Dio singleton, все API методы
        ├── providers/app_state.dart
        ├── models/
        ├── screens/
        └── l10n/app_strings.dart  ← KZ/RU (S.lang)
```

---

## Модели данных

### User
```dart
id, name, role (client|master), phone, city, avatar,
profession, bio, subscription, balance
```

### Order
```dart
id, clientId, masterId, status (new|in_progress|completed|cancelled),
photos[], bidCount, clientDone, masterDone
```

### Master
```dart
id, name, profession, rating, reviewsCount, experience,
isVerified, avatarColor
```

### Bid
```dart
id, orderId, masterId, amount, status (pending|accepted|rejected),
masterAvatarColor, isVerified
```

### Review
```dart
id, rating (1-5), comment, canEdit, hoursRemaining, editableUntil
```

---

## База данных (ключевые таблицы)

```sql
users           — id, name, email, phone, role, city, profession, balance, is_subscribed, avatar_url
orders          — id, client_id, master_id, status, photos, created_at
order_messages  — id, order_id, sender_id, message, msg_type (text|image|system)
order_bids      — id, order_id, master_id, amount, status
order_done      — двустороннее подтверждение завершения
reviews         — rating 1-5, comment, редактируемо 3 дня
master_subscriptions — auto_renew, cancel_at_period_end, next_plan_id
subscription_plans   — title, price, period_days, max_active_orders
fcm_tokens      — push-токены устройств
webrtc_calls / webrtc_signals — WebRTC звонки
```

---

## API эндпоинты (htdocs/api/)

### Авторизация
- `mobile_auth.php` — OTP через SMS прокси
- `email_auth.php` — регистрация/вход по email (нужны колонки `password_hash` и т.д. в БД — см. `db_mobile_init.sql`)
- `csrf.php` — CSRF токен
- `ping.php` — проверка сессии (без логина часто `not_logged_in` — это норма)

### Заказы
- `orders_create.php` — создать заказ
- `orders_list.php` — список заказов клиента
- `orders_feed.php` — лента заказов для мастеров
- `orders_accept.php` — мастер принимает заказ
- `order_get.php` — детали заказа
- `order_finish.php` — завершить заказ
- `orders_guest_create.php` — заказ без авторизации

### Ставки (Bids)
- `orders_bid.php` — сделать ставку
- `orders_bids_list.php` — список ставок
- `orders_bid_respond.php` — принять/отклонить ставку

### Чат
- `messages_list.php` — сообщения (polling 5 сек)
- `messages_send.php` — отправить сообщение
- `message_upload.php` — загрузить фото

### Мастера
- `masters_list.php` — поиск мастеров + фильтры
- `master_status_toggle.php` — онлайн/оффлайн
- `master_stats.php` — статистика
- `master_earnings_chart.php` — график заработка
- `master_reviews.php` — отзывы мастера

### Профиль
- `profile_update.php` — обновить профиль
- `avatar_upload.php` — загрузить аватар
- `portfolio_photos.php` — портфолио
- `save_phone.php` — сохранить телефон
- `role_switch.php` — переключить роль

### GPS / геолокация мастера
- `location_update.php` — мастер шлёт lat/lng (роль `master`, rate limit)
- `location_get.php` — клиент/участник заказа читает последние координаты мастера

---

## Экраны Flutter (sheber_app/lib/screens/)

### Онбординг
- `login_screen.dart` — ввод телефона
- `sms_code_screen.dart` — 6-значный OTP, таймер 60 сек
- `role_select_screen.dart` — клиент или мастер
- `city_select_screen.dart` — выбор города (beta: только Қызылорда)
- `profession_select_screen.dart` — 8 категорий для мастеров
- `diploma_screen.dart` — дипломы/сертификаты

### Навигация
- `main_shell.dart` — IndexedStack, 5 табов, FAB создания заказа
- `tabs/tab_home.dart` — главная
- `tabs/tab_chat.dart` — чаты/заказы
- `tabs/tab_masters.dart` — поиск мастеров + infinite scroll
- `tabs/tab_profile.dart` — профиль

### Клиент
- `client/client_home_screen.dart`
- `client/client_orders_screen.dart` — табы: Active/Completed/Support
- `client/create_order_screen.dart` — форма + Yandex autocomplete + фото

### Мастер
- `master/master_home_screen.dart` — лента + мои заказы
- `master/master_bid_screen.dart` — ставка (min 50% от цены)

### Общие
- `order_chat_screen.dart` — чат + ставки + review + polling
- `order_status_screen.dart` — таймлайн заказа
- `profile_screen.dart` — аватар, имя, bio, опыт, logout
- `subscription_screen.dart` — Premium vs Free + Kaspi оплата

---

## Локализация

Файл: `sheber_app/lib/l10n/app_strings.dart`
- Языки: **KZ** (казахский) и **RU** (русский)
- Переключается через `AppState.language`
- 8 категорий: Сантехника, Электрик, Жөндеу, Тазалық, Терезе, Бояу, Ағаш, Басқа

---

## Архитектурные паттерны

### Polling вместо WebSocket
```dart
// Чат обновляется каждые 5 секунд
Timer.periodic(Duration(seconds: 5), (_) => _loadMessages());
// Звонки polling каждые 2 секунды
Timer.periodic(Duration(seconds: 2), (_) => _pollSignals());
```

### Graceful Migration (PHP)
```php
// Каждый API файл создаёт таблицы/колонки сам при первом вызове
$pdo->exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(255)");
```

### Двустороннее завершение заказа
```sql
-- order_done таблица: заказ = completed только когда ОБА подтвердили
INSERT INTO order_done (order_id, user_id) VALUES (?, ?)
-- completed = EXISTS client_done AND EXISTS master_done
```

### Подписки (Spotify-like)
```php
// subscription_sync() в init.php — ленивая проверка при каждом запросе
// auto_renew списывает с баланса, при нехватке → expired
// 30-дневный Trial при первом role_switch на master
```

---

## Правила кода

### PHP
- Всегда использовать PDO prepared statements (никаких raw queries)
- Структура ответа: `json_out(['ok' => true, 'data' => ...])` или `json_err('msg')`
- Подключать `_boot.php` в начале каждого API файла
- Проверять `require_login()` для защищённых эндпоинтов
- **НИКОГДА** не выводить debug поля в production (`debug`, `_debug_*`)
- Добавлять `IF NOT EXISTS` для всех миграций

### Flutter/Dart
- Использовать `ApiClient` singleton для всех запросов
- Обновлять стейт через `AppState` (Provider)
- Обрабатывать loading/error состояния в каждом экране
- Фото и вложения: нормализовать через `resolveUploadUrl()` (`upload_url.dart`) относительно `kProdBaseUrl` в `app_config.dart`
- Локализация: `S.lang(appState.language)` / строки в `l10n/app_strings.dart`

### Безопасность
- CORS: явный список origin в `api/_boot.php` (прод-домен DuckDNS, Beget, sheber.kz, localhost/127.0.0.1 с портами для разработки)
- Никогда не возвращать `$e->getMessage()` клиенту в JSON (только `server_error` / коды; детали в `error_log`)
- Валидировать все входные данные на сервере

---

## Переменные окружения / Конфиги

```
Прод API (Flutter):  https://sheberkz.duckdns.org  ← app_config.dart / upload_url.dart
VPS:                 см. SHEBER_CURSOR_HANDOFF.md (IP, пути, certbot, Nginx+PHP)
БД (прод):           dbSheberkz, пользователь из config.local.php на сервере
Legacy в доках:      kmaruk4u.beget.tech, kmaruk4u_sheber
Firebase:            sheberkz-116c4
Telegram:            @KenHunterBot
SMS прокси:          usta-auth.vercel.app
Yandex API:          bbox=Kazakhstan (лимиты по тарифу)
```

---

## Статус стабилизации (раньше «известные баги» в этом файле)

Следующие пункты **исправлены в репозитории** (проверено 2026-03):

1. `messages_list.php` — автомиграция колонок (`msg_type`, `file_url`, `is_read`, `read_at`).
2. `order_chat_screen.dart` — изображения через `resolveUploadUrl`.
3. `order.dart` — парсинг `client_done` / `master_done`.
4. `report_user.php` — эндпоинт есть, таблица `user_reports` создаётся при первом вызове.
5. `orders_feed.php` — исключение своих заказов: `o.client_id != ?`.

**Имеет смысл проверять вручную после каждого деплоя:** CSRF на POST, загрузка фото, сценарий «мастер → лента → ставка → чат», HTTPS и Nginx PHP-блок (см. handoff).

---

## Бэклог фич и улучшений (не всё делается «за один раз»)

- [x] API геолокации мастера (`location_update` / `location_get`) + вызовы из приложения
- [x] Система ставок (bid) — основные эндпоинты в `htdocs/api/`
- [x] CORS — ограниченный whitelist в `_boot.php`
- [x] Тёмная тема — `AppState.darkMode` (доработка UI по желанию)
- [x] Клиент не пишет в чат, пока заказ `new` без мастера (UI + `messages_send.php` / `message_upload.php`, код `chat_locked`)
- [x] Завершение заказа: исправлен баг «успех при ошибке API» + разбор JSON при 4xx для `order_finish` / сообщений
- [ ] **Как у конкурентов (Profi.ru, YouDo, Авито Услуги):** push при **новой ставке** (сумма, имя мастера); экран сравнения нескольких ставок; «избранные мастера»; страховка/гарантия (юридически); оплата в приложении или холд; верификация документов; SLA ответа; чат только после матча или оплаты
- [ ] Расширенный профиль мастера в приложении: **био, аватар, портфолио** (на бэке уже есть `avatar_upload.php`, `portfolio_photos.php`, `profile_update.php` — связать в одном экране)
- [ ] Yandex Maps / карта в `create_order_screen` — углублённая интеграция
- [ ] Push: отдельные тексты («мастер предложил цену …»), диплинк в чат заказа
- [ ] WhatsApp / другой канал вместо или вместе с SMS (не позиционировать как основной контакт до реализации)
- [ ] Анимации, кэш картинок в списках, офлайн-индикаторы

---

## Как запускать

```bash
# Flutter
cd sheber_app
flutter analyze   # перед релизом — без замечаний
flutter run

# PHP локально
php -S localhost:8000 -t htdocs/

# Деплой API на VPS (Windows PowerShell, пример)
.\deploy\sync-htdocs.ps1 -IdentityFile "C:\Users\user\.ssh\id_ed25519_sheber"
```
