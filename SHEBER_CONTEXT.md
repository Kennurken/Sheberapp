# SHEBER.KZ — Полный контекст проекта для Claude

> Этот файл передаёт полный контекст разработки Claude с максимальным окном контекста.
> Дата: 20.03.2026

---

## 1. ЧТО ЗА ПРОЕКТ

**Sheber.kz** — Flutter + PHP приложение для рынка домашних услуг (г. Кызылорда, Казахстан).
Аналог naimi.kz / YouDo. Клиенты создают заказы, мастера принимают их.

**Команда:**
- Ты (владелец продукта, вайбкодер) — Flutter + Claude Code
- Друг 1 — Backend PHP
- Друг 2 — Backend PHP (тест/деплой)
- Друг 3 — Дизайн/маркетинг

---

## 2. СТРУКТУРА ПРОЕКТА

```
D:\app\sheber_app\          ← Flutter приложение
  lib\
    api\api_client.dart     ← Dio HTTP клиент, baseUrl
    models\                 ← order.dart, master.dart, bid.dart
    screens\
      tabs\
        tab_home.dart       ← Главная (категории)
        tab_chat.dart       ← Заказы клиента (PUBLIC state: TabChatState)
        tab_masters.dart    ← Список мастеров
      client\
        create_order_screen.dart  ← Создание заказа
      master\
        master_home_screen.dart   ← Лента заказов мастера + GlobalKey
      profile_screen.dart         ← Профиль (смена профессии)
      order_chat_screen.dart      ← Чат по заказу
      main_shell.dart             ← IndexedStack + GlobalKey<TabChatState>
    l10n\
      app_strings.dart      ← Все переводы KZ/RU
      categories.dart       ← 8 категорий (kAppCategories)
    state\app_state.dart    ← Provider: язык, тема, пользователь

C:\xampp\htdocs\sheber_api\ ← PHP бэкенд
  boot.php                  ← PDO SQLite, миграции, auth helpers
  config.php                ← BASE_PATH, константы
  api\
    mobile_auth.php         ← OTP авторизация (пока error_log, без реального SMS)
    orders_create.php       ← Создание заказа + уведомления мастерам
    orders_feed.php         ← Лента заказов для мастера (по profession_category_id)
    orders_list.php         ← Список заказов клиента
    messages_send.php       ← Отправка сообщения
    messages_list.php       ← История чата
    profile_update.php      ← Обновление профиля (+ profession_category_id)
    masters_list.php        ← Список мастеров с фильтром
    reviews_send.php        ← Отправка отзыва
    photo_upload.php        ← Загрузка фото
    report_user.php         ← Жалоба на пользователя
  storage\
    sheber_mobile.sqlite    ← БД SQLite
    .htaccess               ← Запрещает прямой доступ к storage/
```

---

## 3. ТЕКУЩИЙ BASEURL

```dart
// D:\app\sheber_app\lib\api\api_client.dart:20
final String baseUrl = "https://sheberkz.duckdns.org/sheber_api";
```

Сервер: `https://sheberkz.duckdns.org` — DuckDNS домен (бесплатный динамический DNS).

---

## 4. ЧТО УЖЕ СДЕЛАНО И РАБОТАЕТ

### Flutter:
- ✅ Авторизация по SMS (OTP, 6 цифр, 60 сек таймер)
- ✅ Два режима: Клиент / Мастер
- ✅ Клиент: создание заказа по категории → автопереключение на вкладку чата
- ✅ `TabChatState` — публичный, `GlobalKey<TabChatState>` из `MainShell`
- ✅ После создания заказа → `_switchToChat()` → `reload()`
- ✅ Мастер: лента заказов фильтруется по `profession_category_id`
- ✅ Мастер: при смене профессии → лента обновляется
- ✅ `GlobalKey<_MasterFeedTabState>` в `master_home_screen.dart`
- ✅ Автообновление ленты мастера каждые 30 сек (Timer.periodic)
- ✅ Автообновление чата каждые 20 сек
- ✅ Профиль: смена профессии через `_ProfessionSheet` (8 категорий)
- ✅ Тёмная/светлая тема через `Consumer<AppState>` везде
- ✅ KZ/RU переводы через `S.lang(state.language)` везде
- ✅ 8 единых категорий `kAppCategories` в `categories.dart`
- ✅ `CreateOrderScreen(initialCategoryId: id)` — пресет категории с главной

### Backend PHP:
- ✅ SQLite через PDO
- ✅ Сессии + CSRF защита
- ✅ `profession_category_id` INT в users (бэкфил через миграцию)
- ✅ `orders_feed.php` — фильтр по `o.category_id = u.profession_category_id`
- ✅ `orders_create.php` — уведомляет мастеров с совпадающим `profession_category_id`
- ✅ `.htaccess` защищает `storage/`
- ✅ Миграции через `_run_migrations()` в `boot.php`

### Безопасность (аудит проведён):
- ✅ Prepared statements везде (нет SQL injection)
- ✅ CSRF токены
- ✅ `is_blocked` проверка
- ✅ Ownership checks на заказах/сообщениях
- ⚠️ OTP пока в `error_log` (WhatsApp API заблокирован Meta, ждём разблокировки)
- ⚠️ HTTPS настраивается (DuckDNS)

### Firebase:
- ✅ Firebase проект создан: `sheberkz-116c4`
- ✅ `google-services.json` добавлен в `android/app/`
- ✅ FCM API (V1) включён, Sender ID: `242014236222`
- ✅ Service Account JSON скачан → `C:\xampp\htdocs\sheber_api\sheberkz-116c4-firebase-adminsdk-fbsvc....json`
- ❌ `push_register.php` и `push_send.php` — ещё не написаны
- ❌ `firebase_messaging` пакет — ещё не добавлен в `pubspec.yaml`

---

## 5. ЧТО НУЖНО СДЕЛАТЬ (по приоритету)

### ФАЗА 2 — PUSH УВЕДОМЛЕНИЯ (следующая задача)

**Flutter (`pubspec.yaml`):**
```yaml
firebase_core: ^3.0.0
firebase_messaging: ^15.0.0
```

**Flutter (`main.dart`):**
- `await Firebase.initializeApp()`
- Запрос разрешения на уведомления
- Получить FCM токен → POST на `/api/push_register.php`

**PHP новые файлы:**
- `push_register.php` — сохранять FCM токен в таблицу `push_tokens`
- `push_send.php` — отправка через FCM HTTP v1 API (Service Account JSON)
- Вызывать `send_push()` из: `orders_create.php`, `messages_send.php`, `orders_accept.php`

**БД миграция в `boot.php`:**
```sql
CREATE TABLE IF NOT EXISTS push_tokens (
    user_id  INTEGER NOT NULL,
    token    TEXT NOT NULL,
    platform TEXT DEFAULT 'android',
    UNIQUE(user_id, token)
)
```

### ФАЗА 3 — ГЕОЛОКАЦИЯ ЯНДЕКС
- Yandex Suggest API (без тяжёлого SDK): `suggest-maps.yandex.ru/suggest-geo`
- Autocomplete в `create_order_screen.dart`
- Fuzzy поиск в `masters_list.php`: `LIKE %city%`

### ФАЗА 4 — ОКНО РЕДАКТИРОВАНИЯ ОТЗЫВА (3 дня)
- Добавить `editable_until` в reviews таблицу
- `review_update.php` — обновление если в срок
- Flutter: кнопка "Изменить отзыв" в `order_chat_screen.dart`

### ФАЗА 5 — ПРОБНЫЙ PREMIUM (30 дней бесплатно)
- Колонка `subscription` в users
- При регистрации мастера → автоматически premium на 30 дней
- Экран подписки пока **скрыт** (добавим через месяц)

### Через неделю:
- WhatsApp OTP через SendPulse (когда Meta разблокирует)

---

## 6. ВАЖНЫЕ ТЕХНИЧЕСКИЕ ДЕТАЛИ

### GlobalKey паттерн (критично знать):
```dart
// main_shell.dart
final _chatKey = GlobalKey<TabChatState>(); // TabChatState — ПУБЛИЧНЫЙ
void _switchToChat() {
  setState(() => _currentIndex = 1);
  _chatKey.currentState?.reload();
}
// После создания заказа:
Navigator.push(...CreateOrderScreen()).then((_) => _switchToChat());
```

### FCM V1 API (НЕ Legacy):
Legacy API отключён. Использовать V1 с Service Account JSON:
- Endpoint: `https://fcm.googleapis.com/v1/projects/sheberkz-116c4/messages:send`
- Auth: OAuth2 Bearer token из Service Account
- Service Account файл: `sheberkz-116c4-firebase-adminsdk-fbsvc....json`

### OTP сейчас:
```php
// mobile_auth.php — пока только логируем, не отправляем
error_log("[OTP] Phone: {$phone}  Code: {$code}");
// Для теста: код всегда виден в XAMPP error.log
```

### Категории (8 штук, IDs 1-8):
```dart
// categories.dart
kAppCategories: plumber(1), electrician(2), carpenter(3),
  painter(4), cleaner(5), mover(6), welder(7), handyman(8)
```

---

## 7. БД СХЕМА (SQLite)

```sql
users: id, phone, name, role(client/master), city, profession,
       profession_category_id, avatar_url, is_blocked, language,
       created_at

orders: id, client_id, category_id, title, description, address,
        budget, status(searching/in_progress/done/cancelled),
        master_id, created_at

messages: id, order_id, sender_id, text, created_at

bids: id, order_id, master_id, price, comment, status, created_at

reviews: id, master_id, client_id, order_id, rating, comment, created_at

notifications: id, user_id, type, order_id, message, is_read, created_at
```

---

## 8. APK И ДЕПЛОЙ

```
APK: D:\app\sheber_app\build\app\outputs\flutter-apk\app-debug.apk
Сборка: flutter build apk --debug --no-pub
Анализ: flutter analyze (должно быть 0 ошибок)
```

Firebase Service Account JSON:
```
C:\xampp\htdocs\sheber_api\sheberkz-116c4-firebase-adminsdk-fbsvc....json
```
(переименовать в `firebase_service_account.json` перед использованием)

---

## 9. СЛЕДУЮЩИЙ ШАГ ПРЯМО СЕЙЧАС

1. Убедиться что `https://sheberkz.duckdns.org/sheber_api/boot.php` открывается
2. Реализовать push-уведомления (Фаза 2):
   - Добавить `firebase_messaging` в `pubspec.yaml`
   - Написать `push_register.php` и `push_send.php` (FCM V1)
   - Интегрировать в `main.dart`
3. Собрать новый APK и разослать тестерам
