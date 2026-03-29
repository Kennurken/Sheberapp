// Sheber.kz Service Worker — Push + кэш
const CACHE = 'sheber-v1';
const STATIC = ['/index.css', '/assets/js/prefs.js'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(STATIC).catch(() => {})));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(clients.claim());
});

// ── Push event ────────────────────────────────────────────────
self.addEventListener('push', e => {
  if (!e.data) return;
  let payload;
  try { payload = e.data.json(); } catch { payload = { title: 'Sheber.kz', body: e.data.text() }; }

  const title = payload.title || 'Sheber.kz';
  const opts = {
    body:    payload.body  || '',
    icon:    payload.icon  || '/favicon.png',
    badge:   '/favicon.png',
    tag:     payload.tag   || 'sheber-notify',
    data:    payload.data  || {},
    vibrate: [200, 100, 200],
    actions: payload.actions || [],
    requireInteraction: !!payload.requireInteraction,
  };
  e.waitUntil(self.registration.showNotification(title, opts));
});

// ── Notification click ────────────────────────────────────────
self.addEventListener('notificationclick', e => {
  e.notification.close();
  const url = e.notification.data?.url || '/home-master.php';
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      for (const c of list) {
        if (c.url.includes(self.location.origin) && 'focus' in c) {
          c.focus();
          c.postMessage({ type: 'PUSH_CLICK', url });
          return;
        }
      }
      if (clients.openWindow) return clients.openWindow(url);
    })
  );
});

// ── Background fetch fallback ─────────────────────────────────
self.addEventListener('message', e => {
  if (e.data?.type === 'SKIP_WAITING') self.skipWaiting();
});