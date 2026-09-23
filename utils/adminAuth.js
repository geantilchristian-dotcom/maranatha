const { safeEqual, clientIp } = require('./security');
const failures = new Map();
const WINDOW_MS = 15 * 60 * 1000;
const BLOCK_MS = 30 * 60 * 1000;
const MAX_FAILURES = 8;
let lastSweep = 0;
function sweep(now) {
  if (now - lastSweep < WINDOW_MS) return;
  for (const [key, value] of failures) {
    const expiresAt = Math.max(
      value.windowStartedAt + WINDOW_MS,
      value.blockedUntil || 0,
    );
    if (expiresAt <= now) {
      failures.delete(key);
    }
  }
  lastSweep = now;
}
function adminOnly(req, res, next) {
  const expected = process.env.ADMIN_PASSWORD;
  if (!expected) {
    return res.status(503).json({
      error: 'Administration non configurée sur le serveur',
    });
  }
  const now = Date.now();
  sweep(now);
  const key = clientIp(req);
  const current = failures.get(key);
  /*
   * Une IP déjà bloquée reste bloquée
   * jusqu'à l'expiration du délai.
   */
  if (
    current?.blockedUntil &&
    current.blockedUntil > now
  ) {
    const retryAfter = Math.max(
      1,
      Math.ceil(
        (current.blockedUntil - now) / 1000,
      ),
    );
    res.setHeader(
      'Retry-After',
      String(retryAfter),
    );
    return res.status(429).json({
      error:
        'Trop de tentatives. Réessayez plus tard.',
    });
  }
  const provided =
    req.get('x-admin-password');
  /*
   * IMPORTANT :
   *
   * Une requête qui n'envoie aucun mot de passe
   * n'est PAS considérée comme une tentative
   * de mot de passe incorrect.
   *
   * Cela évite que :
   * - les tests API
   * - les diagnostics
   * - certaines requêtes navigateur
   *
   * bloquent accidentellement l'administration.
   */
  if (!provided) {
    return res.status(401).json({
      error: 'Non autorisé',
    });
  }
  /*
   * Ici seulement nous avons réellement reçu
   * un mot de passe incorrect.
   */
  if (!safeEqual(provided, expected)) {
    const state =
      !current ||
      now - current.windowStartedAt >= WINDOW_MS
        ? {
            count: 0,
            windowStartedAt: now,
            blockedUntil: 0,
          }
        : current;
    state.count += 1;
    if (state.count >= MAX_FAILURES) {
      state.blockedUntil =
        now + BLOCK_MS;
    }
    failures.set(
      key,
      state,
    );
    return res.status(401).json({
      error: 'Non autorisé',
    });
  }
  /*
   * Mot de passe correct :
   * on efface les anciens échecs pour cette IP.
   */
  failures.delete(key);
  return next();
}
module.exports = adminOnly;
