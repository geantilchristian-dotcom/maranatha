const express = require('express');
const crypto = require('crypto');
const Don = require('../models/Don');
const AdminNotification = require('../models/AdminNotification');
const adminOnly = require('../utils/adminAuth');
const { cleanText, cleanPhone } = require('../utils/security');

const router = express.Router();

const CATEGORIES = new Set([
  'offrande',
  'dime',
  'don_mensuel',
  'don_volontaire',
]);

function getBaseUrl(req) {
  const configured = String(process.env.MARANATHA_PUBLIC_URL || '')
    .trim()
    .replace(/\/$/, '');
  if (configured) return configured;

  const forwarded = String(req.headers['x-forwarded-proto'] || '')
    .split(',')[0]
    .trim();
  const protocol = forwarded || req.protocol || 'http';
  return `${protocol}://${req.get('host')}`;
}

function normalizeStatus(value) {
  const status = String(value || 'PENDING').trim().toUpperCase();
  if (['COMPLETED', 'PAID', 'SUCCESS', 'SUCCESSFUL'].includes(status)) return 'COMPLETED';
  if (['FAILED', 'FAILURE'].includes(status)) return 'FAILED';
  if (['CANCELLED', 'CANCELED'].includes(status)) return 'CANCELLED';
  if (status === 'PROCESSING') return 'PROCESSING';
  return 'PENDING';
}

function firstHttpUrl(...values) {
  for (const value of values) {
    const text = String(value || '').trim();
    if (/^https?:\/\//i.test(text)) return text;
  }
  return '';
}

function unwrapKpay(payload) {
  if (payload && typeof payload === 'object') {
    if (payload.payment && typeof payload.payment === 'object') return payload.payment;
    if (payload.data && typeof payload.data === 'object') return payload.data;
  }
  return payload || {};
}

function kpayCredentials() {
  return {
    apiKey: String(process.env.KPAY_API_KEY || '').trim(),
    secretKey: String(process.env.KPAY_SECRET_KEY || '').trim(),
  };
}

async function createConfirmationNotification(donation) {
  if (!donation || donation.status !== 'COMPLETED') return;

  const existing = await AdminNotification.findOne({
    type: 'don_confirme',
    reference: donation.externalId,
  }).select('_id').lean();

  if (!existing) {
    const labels = {
      offrande: 'Offrande',
      dime: 'Dîme',
      don_mensuel: 'Don mensuel',
      don_volontaire: 'Don volontaire',
    };

    await AdminNotification.create({
      memberId: donation.memberId || '',
      type: 'don_confirme',
      title: 'Don confirmé',
      nom: donation.donorName || '',
      telephone: donation.donorPhone || '',
      message: `${labels[donation.category] || 'Don'} confirmé par K-PAY.`,
      amount: donation.amount,
      currency: donation.currency || 'CDF',
      donationCategory: donation.category,
      reference: donation.externalId,
      metadata: {
        provider: donation.provider || '',
        kpayReference: donation.kpayReference || '',
      },
    });
  }

  if (!donation.confirmationNotifiedAt) {
    donation.confirmationNotifiedAt = new Date();
    await donation.save();
  }
}

async function syncDonationFromKpay(donation) {
  if (!donation) return null;

  if (donation.status === 'COMPLETED') {
    await createConfirmationNotification(donation);
    return donation;
  }

  if (['FAILED', 'CANCELLED'].includes(donation.status) || !donation.kpayPaymentId) {
    return donation;
  }

  const { apiKey, secretKey } = kpayCredentials();
  if (!apiKey || !secretKey) {
    const error = new Error('Configuration K-PAY incomplète.');
    error.code = 'KPAY_CONFIG';
    throw error;
  }

  const response = await fetch(
    'https://admin.kpay.site/api/v1/payments/' +
      encodeURIComponent(donation.kpayPaymentId),
    {
      method: 'GET',
      headers: {
        'X-API-Key': apiKey,
        'X-Secret-Key': secretKey,
        Accept: 'application/json',
      },
      signal: AbortSignal.timeout(15000),
    },
  );

  const raw = await response.text();
  let payload = {};
  try {
    payload = raw ? JSON.parse(raw) : {};
  } catch (_) {
    payload = {};
  }

  if (!response.ok) {
    const error = new Error('Vérification K-PAY impossible.');
    error.status = response.status;
    throw error;
  }

  const kpay = unwrapKpay(payload);
  const previousStatus = donation.status;
  donation.status = normalizeStatus(kpay.status || payload.status);
  donation.provider = cleanText(kpay.provider || donation.provider || '', 100) || null;
  donation.kpayReference =
    cleanText(kpay.reference || donation.kpayReference || '', 300) || null;

  if (donation.status === 'COMPLETED' && previousStatus !== 'COMPLETED') {
    donation.confirmedAt = donation.confirmedAt || new Date();
  }

  await donation.save();
  await createConfirmationNotification(donation);
  return donation;
}

/* POST /api/dons/kpay/init */
router.post('/kpay/init', async (req, res) => {
  try {
    const { apiKey, secretKey } = kpayCredentials();
    if (!apiKey || !secretKey) {
      return res.status(503).json({
        success: false,
        message: 'La configuration K-PAY est incomplète.',
      });
    }

    const amount = Math.round(Number(req.body?.amount));
    const category = cleanText(req.body?.category, 30).toLowerCase();

    if (!Number.isFinite(amount) || amount < 500 || amount > 100000000) {
      return res.status(400).json({
        success: false,
        message: 'Le montant doit être compris entre 500 et 100 000 000 CDF.',
      });
    }
    if (!CATEGORIES.has(category)) {
      return res.status(400).json({ success: false, message: 'Type de don invalide.' });
    }

    const donorName = cleanText(req.body?.donorName || req.body?.nom, 180);
    const donorPhone = cleanPhone(req.body?.donorPhone || req.body?.telephone);
    const memberId = cleanText(req.body?.memberId, 120);

    const externalId =
      'MARANATHA-DON-' +
      Date.now() +
      '-' +
      crypto.randomBytes(5).toString('hex').toUpperCase();

    const baseUrl = getBaseUrl(req);
    const returnUrl =
      `${baseUrl}/?don=retour&reference=` + encodeURIComponent(externalId);
    const cancelUrl =
      `${baseUrl}/?don=annule&reference=` + encodeURIComponent(externalId);

    const labels = {
      offrande: 'Offrande',
      dime: 'Dîme',
      don_mensuel: 'Don mensuel',
      don_volontaire: 'Don volontaire',
    };

    const donation = await Don.create({
      externalId,
      amount,
      currency: 'CDF',
      category,
      status: 'PENDING',
      donorName,
      donorPhone,
      memberId,
    });

    const response = await fetch('https://admin.kpay.site/api/v1/payments/init', {
      method: 'POST',
      headers: {
        'X-API-Key': apiKey,
        'X-Secret-Key': secretKey,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        amount,
        externalId,
        description: `${labels[category]} - Eglise Maranatha`,
        returnUrl,
        cancelUrl,
        metadata: {
          service: 'MARANATHA_DON',
          donationId: String(donation._id),
          category,
          currency: 'CDF',
        },
      }),
      signal: AbortSignal.timeout(20000),
    });

    const raw = await response.text();
    let payload = {};
    try {
      payload = raw ? JSON.parse(raw) : {};
    } catch (_) {
      payload = {};
    }

    const kpay = unwrapKpay(payload);
    if (!response.ok) {
      donation.status = 'FAILED';
      await donation.save();
      return res.status(response.status).json({
        success: false,
        message: kpay.message || kpay.error || 'K-PAY a refusé le paiement.',
      });
    }

    const gatewayUrl = firstHttpUrl(
      kpay.gatewayUrl,
      kpay.paymentUrl,
      kpay.checkoutUrl,
      kpay.redirectUrl,
      kpay.url,
      payload.gatewayUrl,
      payload.paymentUrl,
      payload.checkoutUrl,
      payload.redirectUrl,
      payload.url,
    );

    if (!gatewayUrl) {
      donation.status = 'FAILED';
      await donation.save();
      return res.status(502).json({
        success: false,
        message: "K-PAY n'a pas retourné de page de paiement.",
      });
    }

    donation.kpayPaymentId = cleanText(kpay.id || payload.id, 300) || null;
    donation.kpayReference = cleanText(kpay.reference || payload.reference, 300) || null;
    donation.gatewayUrl = gatewayUrl;
    donation.status = normalizeStatus(kpay.status || payload.status);
    if (donation.status === 'COMPLETED') donation.confirmedAt = new Date();
    await donation.save();
    await createConfirmationNotification(donation);

    return res.json({
      success: true,
      reference: externalId,
      gatewayUrl,
    });
  } catch (error) {
    console.error('[DON KPAY INIT]', error.message || error);
    return res.status(500).json({
      success: false,
      message:
        error && (error.name === 'TimeoutError' || error.name === 'AbortError')
          ? 'K-PAY ne répond pas pour le moment.'
          : "Impossible d'initialiser le don.",
    });
  }
});

/* GET /api/dons/kpay/status/:reference */
router.get('/kpay/status/:reference', async (req, res) => {
  try {
    const reference = cleanText(req.params.reference, 120);
    const donation = await Don.findOne({ externalId: reference });
    if (!donation) {
      return res.status(404).json({ success: false, message: 'Don introuvable.' });
    }

    const synced = await syncDonationFromKpay(donation);
    return res.json({ success: true, donation: synced });
  } catch (error) {
    console.error('[DON KPAY STATUS]', error.message || error);
    const status = error.code === 'KPAY_CONFIG' ? 503 : (error.status || 500);
    return res.status(status).json({
      success: false,
      message: error.code === 'KPAY_CONFIG'
        ? 'Configuration K-PAY incomplète.'
        : 'Vérification du paiement impossible.',
    });
  }
});

/* GET /api/dons/admin?refresh=1 — admin seulement, dons réellement confirmés */
router.get('/admin', adminOnly, async (req, res) => {
  try {
    if (String(req.query.refresh || '') === '1') {
      const pending = await Don.find({
        status: { $in: ['PENDING', 'PROCESSING'] },
        kpayPaymentId: { $ne: null },
      })
        .sort({ createdAt: -1 })
        .limit(12);

      for (const donation of pending) {
        try {
          await syncDonationFromKpay(donation);
        } catch (error) {
          console.warn('[DON ADMIN REFRESH]', donation.externalId, error.message);
        }
      }
    }

    const donations = await Don.find({ status: 'COMPLETED' })
      .sort({ confirmedAt: -1, updatedAt: -1 })
      .limit(500)
      .lean();

    return res.json({ success: true, donations });
  } catch (error) {
    console.error('[DON ADMIN]', error.message);
    return res.status(500).json({ success: false, donations: [] });
  }
});

module.exports = router;
