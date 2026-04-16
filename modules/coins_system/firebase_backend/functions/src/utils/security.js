const crypto = require('crypto');
const admin = require('firebase-admin');
const { HttpsError } = require('firebase-functions/v2/https');

function sha256(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
}

function randomSecret(size = 32) {
  return crypto.randomBytes(size).toString('hex');
}

function assertAuthenticated(request) {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }
}

function assertAppCheck(request) {
  if (!request.app) {
    throw new HttpsError('failed-precondition', 'App Check token is required.');
  }
}

function requireString(data, key, maxLength = 512) {
  const value = data?.[key];
  if (typeof value !== 'string' || !value.trim() || value.length > maxLength) {
    throw new HttpsError('invalid-argument', `Invalid ${key}.`);
  }
  return value.trim();
}

function requireNumber(data, key) {
  const value = data?.[key];
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw new HttpsError('invalid-argument', `Invalid ${key}.`);
  }
  return value;
}

async function verifyFreshRequest({ db, uid, requestData, action, deviceHash, clientKey }) {
  const timestamp = requireNumber(requestData, 'timestamp');
  const nonce = requireString(requestData, 'nonce', 128);
  const installId = requireString(requestData, 'installId', 128);
  const installTimestamp = requireNumber(requestData, 'installTimestamp');
  const signature = requireString(requestData, 'signature', 256);
  const requestAction = requireString(requestData, 'action', 64);

  if (requestAction !== action) {
    throw new HttpsError('invalid-argument', 'Action mismatch.');
  }

  const now = Date.now();
  if (Math.abs(now - timestamp) > 5 * 60 * 1000) {
    throw new HttpsError('deadline-exceeded', 'Expired request timestamp.');
  }

  const nonceRef = db.collection('request_nonces').doc(`${uid}_${nonce}`);
  const nonceDoc = await nonceRef.get();
  if (nonceDoc.exists) {
    throw new HttpsError('already-exists', 'Replay request blocked.');
  }
  await nonceRef.set({
    uid,
    action,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: admin.firestore.Timestamp.fromMillis(now + 10 * 60 * 1000),
  });

  if (!clientKey) {
    return { installId, installTimestamp, nonce, bootstrap: true };
  }

  const payloadHash = sha256(JSON.stringify(canonicalizePayload(requestData.payload || {})));
  const expected = sha256([
    action,
    uid,
    deviceHash,
    installId,
    String(installTimestamp),
    String(timestamp),
    nonce,
    payloadHash,
    clientKey,
  ].join('|'));
  if (expected !== signature) {
    throw new HttpsError('permission-denied', 'Request signature invalid.');
  }
  return { installId, installTimestamp, nonce, bootstrap: false };
}

function canonicalizePayload(value) {
  if (Array.isArray(value)) {
    return value.map(canonicalizePayload);
  }
  if (value && typeof value === 'object') {
    return Object.keys(value).sort().reduce((acc, key) => {
      acc[key] = canonicalizePayload(value[key]);
      return acc;
    }, {});
  }
  return value;
}

module.exports = {
  assertAuthenticated,
  assertAppCheck,
  canonicalizePayload,
  randomSecret,
  requireNumber,
  requireString,
  sha256,
  verifyFreshRequest,
};
