const CACHE = "maranatha-v20260914-v3";
const STATIC = [
  "/manifest.json",
  "/logo.jpg",
  "/logo-192.png",
  "/logo-512.png"
];

self.addEventListener("install", event => {
  event.waitUntil(
    caches.open(CACHE).then(cache => cache.addAll(STATIC)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(key => key !== CACHE).map(key => caches.delete(key)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", event => {
  if (event.request.method !== "GET") return;

  const url = new URL(event.request.url);

  // Les API et l'administration doivent toujours venir du serveur.
  if (url.pathname.startsWith("/api/") || url.pathname === "/admin" || url.pathname.startsWith("/admin/")) {
    return;
  }

  if (event.request.mode === "navigate") {
    event.respondWith(
      fetch(event.request, { cache: "no-store" })
        .then(response => response)
        .catch(() => caches.match(event.request).then(cached => cached || caches.match("/")))
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then(cached => {
      return cached || fetch(event.request).then(response => {
        if (response && response.ok && url.origin === self.location.origin) {
          const copy = response.clone();
          caches.open(CACHE).then(cache => cache.put(event.request, copy));
        }
        return response;
      });
    })
  );
});

self.addEventListener("message", event => {
  if (event.data && event.data.type === "KEEP_ALIVE" && event.ports[0]) {
    event.ports[0].postMessage({ alive: true });
  }
});
