const express = require("express");
const crypto = require("crypto");
const Don = require("../models/Don");
const router = express.Router();
const CATEGORIES = new Set([
  "offrande",
  "dime",
  "don_mensuel",
  "don_volontaire",
]);
function getBaseUrl(req) {
  const configured =
    String(process.env.MARANATHA_PUBLIC_URL || "")
      .trim()
      .replace(/\/$/, "");
  if (configured) {
    return configured;
  }
  const forwarded =
    String(req.headers["x-forwarded-proto"] || "")
      .split(",")[0]
      .trim();
  const protocol =
    forwarded ||
    req.protocol ||
    "http";
  return `${protocol}://${req.get("host")}`;
}
function normalizeStatus(value) {
  const status =
    String(value || "PENDING")
      .trim()
      .toUpperCase();
  if (
    status === "COMPLETED" ||
    status === "PAID" ||
    status === "SUCCESS" ||
    status === "SUCCESSFUL"
  ) {
    return "COMPLETED";
  }
  if (
    status === "FAILED" ||
    status === "FAILURE"
  ) {
    return "FAILED";
  }
  if (
    status === "CANCELLED" ||
    status === "CANCELED"
  ) {
    return "CANCELLED";
  }
  if (status === "PROCESSING") {
    return "PROCESSING";
  }
  return "PENDING";
}
function unwrapKpay(payload) {
  if (
    payload &&
    typeof payload === "object"
  ) {
    if (
      payload.payment &&
      typeof payload.payment === "object"
    ) {
      return payload.payment;
    }
    if (
      payload.data &&
      typeof payload.data === "object"
    ) {
      return payload.data;
    }
  }
  return payload || {};
}
/*
 * POST /api/dons/kpay/init
 */
router.post(
  "/kpay/init",
  async (req, res) => {
    try {
      const apiKey =
        String(
          process.env.KPAY_API_KEY || ""
        ).trim();
      const secretKey =
        String(
          process.env.KPAY_SECRET_KEY || ""
        ).trim();
      if (!apiKey || !secretKey) {
        return res.status(503).json({
          success: false,
          message:
            "La configuration K-PAY est incomplete.",
        });
      }
      const amount =
        Math.round(
          Number(req.body?.amount)
        );
      const category =
        String(
          req.body?.category || ""
        )
          .trim()
          .toLowerCase();
      if (
        !Number.isFinite(amount) ||
        amount < 500
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Le montant minimum est de 500 CDF.",
        });
      }
      if (!CATEGORIES.has(category)) {
        return res.status(400).json({
          success: false,
          message:
            "Type de don invalide.",
        });
      }
      const externalId =
        "MARANATHA-DON-" +
        Date.now() +
        "-" +
        crypto
          .randomBytes(5)
          .toString("hex")
          .toUpperCase();
      const baseUrl =
        getBaseUrl(req);
      const returnUrl =
        `${baseUrl}/?don=retour&reference=` +
        encodeURIComponent(externalId);
      const cancelUrl =
        `${baseUrl}/?don=annule&reference=` +
        encodeURIComponent(externalId);
      const labels = {
        offrande: "Offrande",
        dime: "Dime",
        don_mensuel: "Don mensuel",
        don_volontaire: "Don volontaire",
      };
      const donation =
        await Don.create({
          externalId,
          amount,
          currency: "CDF",
          category,
          status: "PENDING",
        });
      const response =
        await fetch(
          "https://admin.kpay.site/api/v1/payments/init",
          {
            method: "POST",
            headers: {
              "X-API-Key": apiKey,
              "X-Secret-Key": secretKey,
              "Content-Type":
                "application/json",
              Accept:
                "application/json",
            },
            body: JSON.stringify({
              amount,
              externalId,
              description:
                `${labels[category]} - Eglise Maranatha`,
              returnUrl,
              cancelUrl,
              metadata: {
                service:
                  "MARANATHA_DON",
                donationId:
                  String(donation._id),
                category,
                currency:
                  "CDF",
              },
            }),
          }
        );
      const raw =
        await response.text();
      let payload = {};
      try {
        payload =
          raw
            ? JSON.parse(raw)
            : {};
      } catch (_) {
        payload = {};
      }
      const kpay =
        unwrapKpay(payload);
      if (!response.ok) {
        donation.status =
          "FAILED";
        await donation.save();
        return res
          .status(response.status)
          .json({
            success: false,
            message:
              kpay.message ||
              kpay.error ||
              "K-PAY a refuse le paiement.",
          });
      }
      const gatewayUrl =
        kpay.gatewayUrl ||
        payload.gatewayUrl;
      if (!gatewayUrl) {
        donation.status =
          "FAILED";
        await donation.save();
        return res.status(502).json({
          success: false,
          message:
            "K-PAY n'a pas retourne de page de paiement.",
        });
      }
      donation.kpayPaymentId =
        kpay.id ||
        payload.id ||
        null;
      donation.kpayReference =
        kpay.reference ||
        payload.reference ||
        null;
      donation.gatewayUrl =
        gatewayUrl;
      donation.status =
        normalizeStatus(
          kpay.status ||
          payload.status
        );
      await donation.save();
      return res.json({
        success: true,
        reference:
          externalId,
        gatewayUrl,
      });
    } catch (error) {
      console.error(
        "[DON KPAY INIT]",
        error
      );
      return res.status(500).json({
        success: false,
        message:
          "Impossible d'initialiser le don.",
      });
    }
  }
);
/*
 * GET /api/dons/kpay/status/:reference
 */
router.get(
  "/kpay/status/:reference",
  async (req, res) => {
    try {
      const reference =
        String(
          req.params.reference || ""
        ).trim();
      const donation =
        await Don.findOne({
          externalId:
            reference,
        });
      if (!donation) {
        return res.status(404).json({
          success: false,
          message:
            "Don introuvable.",
        });
      }
      if (
        donation.status === "COMPLETED" ||
        donation.status === "FAILED" ||
        donation.status === "CANCELLED"
      ) {
        return res.json({
          success: true,
          donation,
        });
      }
      if (!donation.kpayPaymentId) {
        return res.json({
          success: true,
          donation,
        });
      }
      const apiKey =
        String(
          process.env.KPAY_API_KEY || ""
        ).trim();
      const secretKey =
        String(
          process.env.KPAY_SECRET_KEY || ""
        ).trim();
      if (!apiKey || !secretKey) {
        return res.status(503).json({
          success: false,
          message:
            "Configuration K-PAY incomplete.",
        });
      }
      const response =
        await fetch(
          "https://admin.kpay.site/api/v1/payments/" +
          encodeURIComponent(
            donation.kpayPaymentId
          ),
          {
            method: "GET",
            headers: {
              "X-API-Key":
                apiKey,
              "X-Secret-Key":
                secretKey,
              Accept:
                "application/json",
            },
          }
        );
      const raw =
        await response.text();
      let payload = {};
      try {
        payload =
          raw
            ? JSON.parse(raw)
            : {};
      } catch (_) {
        payload = {};
      }
      if (!response.ok) {
        return res
          .status(response.status)
          .json({
            success: false,
            message:
              "Verification K-PAY impossible.",
          });
      }
      const kpay =
        unwrapKpay(payload);
      donation.status =
        normalizeStatus(
          kpay.status ||
          payload.status
        );
      donation.provider =
        kpay.provider ||
        null;
      donation.kpayReference =
        kpay.reference ||
        donation.kpayReference;
      await donation.save();
      return res.json({
        success: true,
        donation,
      });
    } catch (error) {
      console.error(
        "[DON KPAY STATUS]",
        error
      );
      return res.status(500).json({
        success: false,
        message:
          "Verification du paiement impossible.",
      });
    }
  }
);
module.exports = router;
