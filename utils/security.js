const crypto = require('crypto');

function cleanText(value, maxLength = 500) {
  return String(value == null ? '' : value)
    .replace(/\u0000/g, '')
    .trim()
    .slice(0, Math.max(0, maxLength));
}

function cleanHttpUrl(value, maxLength = 1500) {
  const raw = cleanText(value, maxLength);
  if (!raw) return '';
  try {
    const parsed = new URL(raw);
    if (!['http:', 'https:'].includes(parsed.protocol)) return '';
    return parsed.toString();
  } catch (_) {
    return '';
  }
}

function cleanEmail(value) {
  const email = cleanText(value, 254).toLowerCase();
  if (!email) return '';
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ? email : '';
}

function cleanPhone(value) {
  return cleanText(value, 40).replace(/[^0-9+() .-]/g, '');
}

function safeEqual(left, right) {
  const a = Buffer.from(String(left || ''), 'utf8');
  const b = Buffer.from(String(right || ''), 'utf8');
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function clientIp(req) {
  return cleanText(
    (req.headers['cf-connecting-ip'] ||
      req.headers['x-real-ip'] ||
      req.ip ||
      req.socket?.remoteAddress ||
      'unknown'),
    160,
  );
}

function createRateLimiter({ windowMs = 60_000, max = 30, keyPrefix = 'rate' } = {}) {
  const hits = new Map();
  let lastSweep = 0;

  return function rateLimiter(req, res, next) {
    const now = Date.now();

    if (now - lastSweep > Math.max(windowMs, 60_000)) {
      for (const [key, value] of hits) {
        if (value.resetAt <= now) hits.delete(key);
      }
      lastSweep = now;
    }

    const key = `${keyPrefix}:${clientIp(req)}`;
    const current = hits.get(key);

    if (!current || current.resetAt <= now) {
      hits.set(key, { count: 1, resetAt: now + windowMs });
      return next();
    }

    current.count += 1;
    hits.set(key, current);

    if (current.count > max) {
      const retryAfter = Math.max(1, Math.ceil((current.resetAt - now) / 1000));
      res.setHeader('Retry-After', String(retryAfter));
      return res.status(429).json({
        error: 'Trop de requêtes. Réessayez dans quelques instants.',
      });
    }

    return next();
  };
}

function securityHeaders(req, res, next) {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader(
    'Permissions-Policy',
    'camera=(), microphone=(), geolocation=(), payment=(self)',
  );
  res.setHeader('Cross-Origin-Resource-Policy', 'same-site');

  if (process.env.NODE_ENV === 'production') {
    res.setHeader(
      'Strict-Transport-Security',
      'max-age=31536000; includeSubDomains',
    );
  }

  if (
    req.path === '/admin' ||
    req.path === '/admin.html' ||
    req.path.startsWith('/api/') ||
    req.path === '/api'
  ) {
    res.setHeader('Cache-Control', 'no-store');
  }

  next();
}

module.exports = {
  cleanText,
  cleanHttpUrl,
  cleanEmail,
  cleanPhone,
  safeEqual,
  clientIp,
  createRateLimiter,
  securityHeaders,
};
