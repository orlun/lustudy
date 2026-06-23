const C = 'lustudy-v26';
const ASSETS = ['./', './index.html', './manifest.webmanifest', './icon-192.png', './icon-512.png', './bg.svg'];
self.addEventListener('install', e => { e.waitUntil(caches.open(C).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()).catch(() => {})); });
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.map(k => k !== C ? caches.delete(k) : null))).then(() => self.clients.claim())); });
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  let u; try { u = new URL(req.url); } catch (err) { return; }
  if (u.origin !== location.origin) return;
  // network-first: siempre lo último de la web; caché solo si no hay conexión
  e.respondWith(
    fetch(req).then(r => { const cp = r.clone(); caches.open(C).then(c => c.put(req, cp)).catch(() => {}); return r; })
      .catch(() => caches.match(req).then(c => c || caches.match('./index.html')))
  );
});
