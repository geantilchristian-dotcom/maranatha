const mongoose = require('mongoose');

const donSchema = new mongoose.Schema(
  {
    externalId: {
      type: String,
      required: true,
      unique: true,
      index: true,
      maxlength: 120,
    },
    amount: {
      type: Number,
      required: true,
      min: 1,
      max: 1000000000,
    },
    currency: {
      type: String,
      default: 'CDF',
      maxlength: 10,
    },
    category: {
      type: String,
      required: true,
      enum: ['offrande', 'dime', 'don_mensuel', 'don_volontaire'],
    },
    status: {
      type: String,
      enum: ['PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED'],
      default: 'PENDING',
      index: true,
    },
    donorName: { type: String, default: '', trim: true, maxlength: 180 },
    donorPhone: { type: String, default: '', trim: true, maxlength: 60 },
    memberId: { type: String, default: '', trim: true, maxlength: 120 },
    kpayPaymentId: { type: String, default: null, maxlength: 300 },
    kpayReference: { type: String, default: null, maxlength: 300 },
    gatewayUrl: { type: String, default: null, maxlength: 1800 },
    provider: { type: String, default: null, maxlength: 100 },
    confirmedAt: { type: Date, default: null, index: true },
    confirmationNotifiedAt: { type: Date, default: null },
  },
  { timestamps: true },
);

donSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.models.Don || mongoose.model('Don', donSchema);
