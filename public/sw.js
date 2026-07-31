const CACHE = 'maranatha-v20260730';
const STATIC = ['/', '/index.html', '/manifest.json', '/logo.jpg', '/logo-192.png', '/logo-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(STATIC)).catch(() => {}));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  const url = new URL(e.request.url);
  if (url.pathname.startsWith('/api/')) return;
  e.respondWith(
    caches.match(e.request).then(cached => cached || fetch(e.request).catch(() => cached))
  );
});

self.addEventListener('message', e => {
  if (e.data && e.data.type === 'KEEP_ALIVE' && e.ports[0]) {
    e.ports[0].postMessage({ alive: true });
  }
});
