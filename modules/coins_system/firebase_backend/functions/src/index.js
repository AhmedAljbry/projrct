const admin = require('firebase-admin');
const { onCall } = require('firebase-functions/v2/https');

const {
  registerUser,
  rewardAd,
  verifyPurchase,
} = require('./services/coins_service');

admin.initializeApp();

const callableOptions = {
  region: process.env.FUNCTIONS_REGION || 'us-central1',
  enforceAppCheck: true,
  cors: true,
};

exports.registerUser = onCall(callableOptions, registerUser);
exports.rewardAd = onCall(callableOptions, rewardAd);
exports.verifyPurchase = onCall(callableOptions, verifyPurchase);
