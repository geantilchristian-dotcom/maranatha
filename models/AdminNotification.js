const mongoose = require("mongoose");
const adminNotificationSchema =
  new mongoose.Schema(
    {
      memberId: {
        type: String,
        default: "",
        index: true,
      },
      type: {
        type: String,
        required: true,
        index: true,
      },
      title: {
        type: String,
        default: "",
      },
      nom: {
        type: String,
        default: "",
      },
      adresse: {
        type: String,
        default: "",
      },
      telephone: {
        type: String,
        default: "",
      },
      email: {
        type: String,
        default: "",
      },
      message: {
        type: String,
        default: "",
      },
      amount: {
        type: Number,
        default: null,
      },
      currency: {
        type: String,
        default: "CDF",
      },
      donationCategory: {
        type: String,
        default: "",
      },
      reference: {
        type: String,
        default: "",
      },
      read: {
        type: Boolean,
        default: false,
        index: true,
      },
      processed: {
        type: Boolean,
        default: false,
      },
      metadata: {
        type: mongoose.Schema.Types.Mixed,
        default: {},
      },
    },
    {
      timestamps: true,
    }
  );
module.exports =
  mongoose.models.AdminNotification ||
  mongoose.model(
    "AdminNotification",
    adminNotificationSchema
  );
