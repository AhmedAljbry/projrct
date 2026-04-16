const admin = require('firebase-admin');
const { HttpsError } = require('firebase-functions/v2/https');

const {
  assertAuthenticated,
  assertAppCheck,
  randomSecret,
  requireNumber,
  requireString,
  verifyFreshRequest,
} = require('../utils/security');
const { verifyProductPurchase } = require('./play_billing_service');

const INITIAL_REWARD = 10;
const AD_REWARD_COINS = Number(process.env.AD_REWARD_COINS || 2);
const MAX_HOURLY_AD_REWARDS = Number(process.env.MAX_HOURLY_AD_REWARDS || 20);
const PRODUCT_COINS = JSON.parse(process.env.PLAY_PRODUCT_COINS || '{}');

async function registerUser(request) {
  assertAuthenticated(request);
  assertAppCheck(request);

  const uid = request.auth.uid;
  const data = request.data || {};
  const deviceHash = requireString(data, 'deviceHash', 256);
  const fingerprintSignature = requireString(data, 'fingerprintSignature', 256);
  const installTimestamp = requireNumber(data, 'installTimestamp');
  const installId = requireString(data, 'installId', 128);
  const db = admin.firestore();

  await verifyFreshRequest({
    db,
    uid,
    requestData: {
      ...data.request,
      payload: {
        deviceHash,
        fingerprintSignature,
        installTimestamp,
      },
    },
    action: 'registerUser',
    deviceHash,
    clientKey: null,
  });

  const userRef = db.collection('users').doc(uid);
  const deviceRef = db.collection('devices').doc(deviceHash);
  const privateRef = db.collection('users_private').doc(uid);
  const transactionRef = db.collection('transactions').doc();

  const result = await db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    const deviceDoc = await tx.get(deviceRef);
    let coins = userDoc.exists ? (userDoc.data().coins || 0) : 0;
    let granted = 0;
    let suspicious = false;

    if (!userDoc.exists && !deviceDoc.exists) {
      granted = INITIAL_REWARD;
      coins += granted;
      tx.set(deviceRef, {
        firstUserId: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        installTimestamp,
        installId,
        lastAppCheckAppId: request.app.appId || '',
        fingerprintSignature,
        accountCount: 1,
      });
    } else if (!userDoc.exists && deviceDoc.exists) {
      suspicious = deviceDoc.data().firstUserId !== uid;
      tx.set(deviceRef, {
        accountCount: admin.firestore.FieldValue.increment(1),
        lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    tx.set(userRef, {
      coins,
      createdAt: userDoc.exists ? userDoc.data().createdAt : admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      deviceHash,
      fingerprintSignature,
      installTimestamp,
      lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    const clientKey = randomSecret(24);
    tx.set(privateRef, {
      clientKey,
      lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
      suspiciousReuse: suspicious,
      installId,
    }, { merge: true });

    if (granted > 0) {
      tx.set(transactionRef, {
        userId: uid,
        type: 'initial',
        amount: granted,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        deviceHash,
        metadata: {
          installTimestamp,
        },
      });
    }

    if (suspicious) {
      tx.set(db.collection('abuse_flags').doc(), {
        userId: uid,
        type: 'device_reuse',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        deviceHash,
      });
    }

    return { coins, granted, clientKey };
  });

  return {
    success: true,
    granted: result.granted,
    clientKey: result.clientKey,
    user: {
      coins: result.coins,
      createdAt: new Date().toISOString(),
      deviceHash,
      fingerprintSignature,
    },
  };
}

async function rewardAd(request) {
  assertAuthenticated(request);
  assertAppCheck(request);

  const uid = request.auth.uid;
  const data = request.data || {};
  const deviceHash = requireString(data, 'deviceHash', 256);
  const fingerprintSignature = requireString(data, 'fingerprintSignature', 256);
  const db = admin.firestore();
  const privateRef = db.collection('users_private').doc(uid);
  const privateDoc = await privateRef.get();
  const clientKey = privateDoc.data()?.clientKey;

  const verified = await verifyFreshRequest({
    db,
    uid,
    requestData: {
      ...data.request,
      payload: {
        deviceHash,
        fingerprintSignature,
      },
    },
    action: 'rewardAd',
    deviceHash,
    clientKey,
  });

  const userRef = db.collection('users').doc(uid);
  const now = Date.now();
  const hourBucket = Math.floor(now / (60 * 60 * 1000));

  return db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    const freshPrivateDoc = await tx.get(privateRef);
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User wallet not found.');
    }

    const privateData = freshPrivateDoc.data() || {};
    const lastRewardAt = privateData.lastRewardAt?.toMillis?.() || 0;
    if (now - lastRewardAt < 60 * 1000) {
      throw new HttpsError('resource-exhausted', 'Reward cooldown is 60 seconds.');
    }

    const currentBucket = privateData.rewardHourBucket || hourBucket;
    const currentCount = currentBucket === hourBucket ? (privateData.rewardHourCount || 0) : 0;
    if (currentCount >= MAX_HOURLY_AD_REWARDS) {
      throw new HttpsError('resource-exhausted', 'Hourly reward limit reached.');
    }

    if (userDoc.data().deviceHash !== deviceHash || userDoc.data().fingerprintSignature !== fingerprintSignature) {
      tx.set(db.collection('abuse_flags').doc(), {
        userId: uid,
        type: 'fingerprint_mismatch',
        deviceHash,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        verified,
      });
      throw new HttpsError('permission-denied', 'Suspicious device fingerprint.');
    }

    const newBalance = (userDoc.data().coins || 0) + AD_REWARD_COINS;
    tx.set(userRef, {
      coins: newBalance,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    tx.set(privateRef, {
      lastRewardAt: admin.firestore.Timestamp.fromMillis(now),
      rewardHourBucket: hourBucket,
      rewardHourCount: currentCount + 1,
    }, { merge: true });
    tx.set(db.collection('transactions').doc(), {
      userId: uid,
      type: 'ad',
      amount: AD_REWARD_COINS,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      deviceHash,
      metadata: {
        nonce: verified.nonce,
      },
    });

    return {
      success: true,
      coinsAdded: AD_REWARD_COINS,
      balance: newBalance,
      message: 'Reward granted.',
    };
  });
}

async function verifyPurchase(request) {
  assertAuthenticated(request);
  assertAppCheck(request);

  const uid = request.auth.uid;
  const data = request.data || {};
  const deviceHash = requireString(data, 'deviceHash', 256);
  const fingerprintSignature = requireString(data, 'fingerprintSignature', 256);
  const productId = requireString(data, 'productId', 256);
  const purchaseToken = requireString(data, 'purchaseToken', 1024);
  const packageName = requireString(data, 'packageName', 256);
  const db = admin.firestore();

  const privateDoc = await db.collection('users_private').doc(uid).get();
  await verifyFreshRequest({
    db,
    uid,
    requestData: {
      ...data.request,
      payload: {
        productId,
        purchaseToken,
        source: data.source || '',
      },
    },
    action: 'verifyPurchase',
    deviceHash,
    clientKey: privateDoc.data()?.clientKey,
  });

  const coinsToAdd = PRODUCT_COINS[productId];
  if (!coinsToAdd) {
    throw new HttpsError('invalid-argument', 'Product is not configured.');
  }

  const purchaseRef = db.collection('purchases').doc(purchaseToken);
  const purchaseDoc = await purchaseRef.get();
  if (purchaseDoc.exists && purchaseDoc.data().rewarded === true) {
    return {
      success: true,
      coinsAdded: 0,
      balance: purchaseDoc.data().balanceSnapshot || 0,
      message: 'Purchase already processed.',
    };
  }

  if (packageName !== process.env.ANDROID_PACKAGE_NAME) {
    throw new HttpsError('permission-denied', 'Package name mismatch.');
  }

  const purchase = await verifyProductPurchase({
    packageName,
    productId,
    purchaseToken,
  });

  const userRef = db.collection('users').doc(uid);
  return db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'Wallet not found.');
    }

    if (userDoc.data().deviceHash !== deviceHash || userDoc.data().fingerprintSignature !== fingerprintSignature) {
      throw new HttpsError('permission-denied', 'Suspicious device fingerprint.');
    }

    const newBalance = (userDoc.data().coins || 0) + coinsToAdd;
    tx.set(userRef, {
      coins: newBalance,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    tx.set(purchaseRef, {
      userId: uid,
      productId,
      packageName,
      orderId: purchase.orderId || '',
      purchaseTimeMillis: purchase.purchaseTimeMillis || '',
      purchaseState: purchase.purchaseState,
      consumptionState: purchase.consumptionState,
      acknowledgementState: purchase.acknowledgementState,
      rewarded: true,
      balanceSnapshot: newBalance,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    tx.set(db.collection('transactions').doc(), {
      userId: uid,
      type: 'purchase',
      amount: coinsToAdd,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      deviceHash,
      metadata: {
        productId,
        orderId: purchase.orderId || '',
      },
    });

    return {
      success: true,
      coinsAdded: coinsToAdd,
      balance: newBalance,
      message: 'Purchase verified.',
    };
  });
}

module.exports = {
  registerUser,
  rewardAd,
  verifyPurchase,
};
