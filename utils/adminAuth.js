const crypto = require('crypto');

function safeEqual(left, right) {
  const a = Buffer.from(String(left || ''), 'utf8');
  const b = Buffer.from(String(right || ''), 'utf8');
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function adminOnly(req, res, next) {
  const expected = process.env.ADMIN_PASSWORD;
  if (!expected) {
    return res.status(503).json({
      error: 'Administration non configurée sur le serveur',
    });
  }

  const provided = req.get('x-admin-password');
  if (!provided || !safeEqual(provided, expected)) {
    return res.status(401).json({ error: 'Non autorisé' });
  }

  next();
}

module.exports = adminOnly;
