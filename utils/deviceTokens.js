const Device = require('../models/Device');
const User = require('../models/User');

async function obtenirTokensActifs() {
  const expiration = new Date(Date.now() - 120 * 24 * 60 * 60 * 1000);

  const [devices, users] = await Promise.all([
    Device.find({
      modeMaranathaActif: true,
      fcmToken: { $type: 'string', $ne: '' },
      lastSeenAt: { $gte: expiration },
    })
      .select({ fcmToken: 1 })
      .lean(),
    User.find({
      modeMaranathaActif: true,
      role: 'fidele',
      fcmToken: { $type: 'string', $ne: '' },
    })
      .select({ fcmToken: 1 })
      .lean(),
  ]);

  return [
    ...new Set(
      [...devices, ...users]
        .map((item) => String(item.fcmToken || '').trim())
        .filter(Boolean),
    ),
  ];
}

// Publication notifications are independent from the alarm opt-in switch.
// Keep the same recency window so stale registrations do not receive pushes.
async function obtenirTokensRecents() {
  const expiration = new Date(Date.now() - 120 * 24 * 60 * 60 * 1000);

  const [devices, users] = await Promise.all([
    Device.find({
      fcmToken: { $type: 'string', $ne: '' },
      lastSeenAt: { $gte: expiration },
    }).select({ fcmToken: 1 }).lean(),
    User.find({
      fcmToken: { $type: 'string', $ne: '' },
      dateInscription: { $gte: expiration },
    }).select({ fcmToken: 1 }).lean(),
  ]);

  return [...new Set([...devices, ...users]
    .map((item) => String(item.fcmToken || '').trim())
    .filter(Boolean))];
}

module.exports = { obtenirTokensActifs, obtenirTokensRecents };
