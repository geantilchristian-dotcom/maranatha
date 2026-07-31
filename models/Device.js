const mongoose = require('mongoose');

const deviceSchema = new mongoose.Schema(
  {
    installationId: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      maxlength: 220,
    },
    fcmToken: {
      type: String,
      required: true,
      trim: true,
      maxlength: 4096,
      index: true,
    },
    platform: {
      type: String,
      enum: ['android', 'ios', 'web'],
      default: 'android',
    },
    appVersion: {
      type: String,
      default: '',
      trim: true,
      maxlength: 80,
    },
    modeMaranathaActif: {
      type: Boolean,
      default: false,
      index: true,
    },
    lastSeenAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
  },
  {
    timestamps: true,
  },
);

deviceSchema.index({ modeMaranathaActif: 1, lastSeenAt: -1 });

module.exports = mongoose.model('Device', deviceSchema);
