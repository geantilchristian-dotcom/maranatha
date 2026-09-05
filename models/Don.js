const mongoose = require("mongoose");
const donSchema = new mongoose.Schema(
  {
    externalId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    amount: {
      type: Number,
      required: true,
      min: 1,
    },
    currency: {
      type: String,
      default: "CDF",
    },
    category: {
      type: String,
      required: true,
      enum: [
        "offrande",
        "dime",
        "don_mensuel",
        "don_volontaire",
      ],
    },
    status: {
      type: String,
      default: "PENDING",
    },
    kpayPaymentId: {
      type: String,
      default: null,
    },
    kpayReference: {
      type: String,
      default: null,
    },
    gatewayUrl: {
      type: String,
      default: null,
    },
    provider: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);
module.exports = mongoose.model("Don", donSchema);
