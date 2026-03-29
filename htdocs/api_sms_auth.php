<?php
declare(strict_types=1);
require __DIR__ . '/init.php';

$me = current_user($pdo);
if (!$me) {
  api_fatal('not_authorized', 401);
}

header('Content-Type: application/json; charset=utf-8');

$action = (string)($_GET['action'] ?? $_POST['action'] ?? '');

// ============================================
// 1. ОТПРАВИТЬ КОД НА НОМЕР
// ============================================
if ($action === 'send_code') {
  $phone = (string)($_POST['phone'] ?? '');
  
  // Валидация телефона
  if (empty($phone)) {
    echo json_encode(['ok' => false, 'error' => 'Номер телефона обязателен']);
    exit;
  }
  
  // Очистить номер от не-цифр
  $phone_clean = preg_replace('/[^0-9+]/', '', $phone);
  
  // Проверить, не привязан ли номер к другому аккаунту
  $st = $pdo->prepare("SELECT id FROM users WHERE phone = ? AND id != ? LIMIT 1");
  $st->execute([$phone_clean, (int)$me['id']]);
  if ($st->fetch()) {
    echo json_encode(['ok' => false, 'error' => 'Этот номер уже привязан к другому аккаунту']);
    exit;
  }
  
  // Отправить код через Vercel API
  $vercelUrl = 'https://usta-auth.vercel.app/api/send';
  $ch = curl_init($vercelUrl);
  $payload = json_encode(['phone' => $phone_clean]);
  
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_POST, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
  curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
  curl_setopt($ch, CURLOPT_TIMEOUT, 10);
  
  $response = curl_exec($ch);
  $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
  $error = curl_error($ch);
  curl_close($ch);
  
  if ($response === false) {
    error_log("SMS Send Error: " . $error);
    echo json_encode(['ok' => false, 'error' => 'Ошибка при отправке кода']);
    exit;
  }
  
  $responseData = json_decode($response, true);
  
  if ($httpCode === 200 && isset($responseData['success']) && $responseData['success'] === true) {
    // Успешно отправлено
    $_SESSION['sms_pending_phone'] = $phone_clean;
    $_SESSION['sms_pending_time'] = time();
    echo json_encode(['ok' => true, 'message' => 'Код отправлен на номер']);
  } else {
    $errMsg = $responseData['error'] ?? 'Не удалось отправить код';
    echo json_encode(['ok' => false, 'error' => $errMsg]);
  }
  exit;
}

// ============================================
// 2. ПРОВЕРИТЬ КОД И СОХРАНИТЬ НОМЕР
// ============================================
if ($action === 'verify_code') {
  $code = (string)($_POST['code'] ?? '');
  
  // Получить номер из сессии
  $phone = $_SESSION['sms_pending_phone'] ?? null;
  if (!$phone || empty($code)) {
    echo json_encode(['ok' => false, 'error' => 'Ошибка: данные потеряны']);
    exit;
  }
  
  // Проверить, не истекло ли время (10 минут)
  $sms_time = $_SESSION['sms_pending_time'] ?? 0;
  if (time() - $sms_time > 600) {
    unset($_SESSION['sms_pending_phone'], $_SESSION['sms_pending_time']);
    echo json_encode(['ok' => false, 'error' => 'Код истек. Запросите новый']);
    exit;
  }
  
  // Проверить код через Vercel API
  $vercelUrl = 'https://usta-auth.vercel.app/api/verify';
  $ch = curl_init($vercelUrl);
  $payload = json_encode(['phone' => $phone, 'code' => $code]);
  
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_POST, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
  curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
  curl_setopt($ch, CURLOPT_TIMEOUT, 10);
  
  $response = curl_exec($ch);
  $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);
  
  if ($response === false) {
    echo json_encode(['ok' => false, 'error' => 'Ошибка связи с сервером']);
    exit;
  }
  
  $responseData = json_decode($response, true);
  
  if ($httpCode === 200 && isset($responseData['success']) && $responseData['success'] === true) {
    // КОД ВЕРНЫЙ! Сохранить номер в БД
    $st = $pdo->prepare("UPDATE users SET phone = ? WHERE id = ?");
    if ($st->execute([$phone, (int)$me['id']])) {
      // Очистить сессию
      unset($_SESSION['sms_pending_phone'], $_SESSION['sms_pending_time']);
      
      echo json_encode([
        'ok' => true, 
        'message' => 'Номер успешно подтвержден!',
        'phone' => $phone
      ]);
    } else {
      echo json_encode(['ok' => false, 'error' => 'Ошибка сохранения номера']);
    }
  } else {
    // Неверный код
    $errMsg = $responseData['error'] ?? 'Неверный код';
    echo json_encode(['ok' => false, 'error' => $errMsg]);
  }
  exit;
}

// ============================================
// 3. ПОЛУЧИТЬ ТЕКУЩИЙ СТАТУС
// ============================================
if ($action === 'get_status') {
  $phone = (string)($me['phone'] ?? '');
  $is_verified = !empty($phone);
  
  echo json_encode([
    'ok' => true,
    'phone' => $phone,
    'is_verified' => $is_verified,
    'pending_phone' => $_SESSION['sms_pending_phone'] ?? null
  ]);
  exit;
}

// ============================================
// 4. УДАЛИТЬ НОМЕР ТЕЛЕФОНА
// ============================================
if ($action === 'remove_phone') {
  $st = $pdo->prepare("UPDATE users SET phone = '' WHERE id = ?");
  if ($st->execute([(int)$me['id']])) {
    echo json_encode(['ok' => true, 'message' => 'Номер удален']);
  } else {
    echo json_encode(['ok' => false, 'error' => 'Ошибка при удалении']);
  }
  exit;
}

// Неизвестное действие
echo json_encode(['ok' => false, 'error' => 'Неизвестное действие']);