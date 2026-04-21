const admin = require('firebase-admin');
const { HttpsError } = require('firebase-functions/v2/https');

const { sha256 } = require('../utils/security');

const db = admin.firestore();
const INSTALLATION_PEPPER =
  process.env.INSTALLATION_HASH_PEPPER || 'replace-me-with-a-secret-pepper';

function installationHash(installationId) {
  return sha256(`${INSTALLATION_PEPPER}|${installationId}`);
}

function getIpAddress(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.trim()) {
    return forwarded.split(',')[0].trim();
  }
  return req.ip || 'unknown';
}

function getBearerToken(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) {
    throw new HttpsError('unauthenticated', 'Missing Firebase Auth token.');
  }
  return header.slice('Bearer '.length);
}

async function verifyRequestContext(req) {
  const authToken = getBearerToken(req);
  const appCheckToken = req.headers['x-firebase-appcheck'];

  if (typeof appCheckToken !== 'string' || !appCheckToken.trim()) {
    throw new HttpsError('failed-precondition', 'Missing App Check token.');
  }

  const [auth, appCheck] = await Promise.all([
    admin.auth().verifyIdToken(authToken, true),
    admin.appCheck().verifyToken(appCheckToken),
  ]);

  return { auth, appCheck };
}

function requireString(value, field, maxLength = 256) {
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `Invalid ${field}.`);
  }
  const trimmed = value.trim();
  if (!trimmed || trimmed.length > maxLength) {
    throw new HttpsError('invalid-argument', `Invalid ${field}.`);
  }
  return trimmed;
}

function requireObject(value, field) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpsError('invalid-argument', `Invalid ${field}.`);
  }
  return value;
}

function requireTimestamp(value, field) {
  if (!Number.isFinite(value)) {
    throw new HttpsError('invalid-argument', `Invalid ${field}.`);
  }
  const now = Date.now();
  if (Math.abs(now - value) > 5 * 60 * 1000) {
    throw new HttpsError('deadline-exceeded', `${field} expired.`);
  }
  return value;
}

async function ensureFreshNonce({ uid, nonce, timestampMs }) {
  requireTimestamp(timestampMs, 'request_timestamp_ms');
  const nonceRef = db.collection('request_nonces').doc(`${uid}_${nonce}`);
  const nonceDoc = await nonceRef.get();
  if (nonceDoc.exists) {
    throw new HttpsError('already-exists', 'Replay request blocked.');
  }
  await nonceRef.set({
    uid,
    nonce,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    expires_at: admin.firestore.Timestamp.fromMillis(
      Date.now() + 10 * 60 * 1000,
    ),
  });
}

async function incrementRateLimit(key, limit, windowMinutes) {
  const bucket = Math.floor(Date.now() / (windowMinutes * 60 * 1000));
  const ref = db.collection('signup_rate_limits').doc(`${key}_${bucket}`);

  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const count = snapshot.exists ? snapshot.data().count || 0 : 0;
    if (count >= limit) {
      throw new HttpsError('resource-exhausted', 'Rate limit exceeded.');
    }
    tx.set(
      ref,
      {
        key,
        bucket,
        count: count + 1,
        window_minutes: windowMinutes,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        expires_at: admin.firestore.Timestamp.fromMillis(
          Date.now() + windowMinutes * 60 * 1000,
        ),
      },
      { merge: true },
    );
  });
}

function scoreRisk({ riskSignals, appCheck, existingInstallation, ipAttemptCount }) {
  let score = 0;
  const flags = [];

  if (!appCheck.alreadyConsumed && appCheck.appId) {
    score += 0;
  } else {
    score += 30;
    flags.push('app_check_anomaly');
  }

  if (riskSignals.is_debug_build) {
    score += 15;
    flags.push('debug_build');
  }
  if (riskSignals.is_emulator) {
    score += 20;
    flags.push('emulator');
  }
  if (riskSignals.is_rooted) {
    score += 30;
    flags.push('rooted_or_jailbroken');
  }
  if (existingInstallation) {
    score += 100;
    flags.push('installation_reuse');
  }
  if (ipAttemptCount >= 5) {
    score += 30;
    flags.push('ip_velocity');
  }

  const decision =
    score >= 80 ? 'BLOCK' : score >= 40 ? 'REQUIRE_VERIFICATION' : 'ALLOW';
  return { score, flags, decision };
}

async function countRecentAttempts(ipAddress) {
  const snapshot = await db
    .collection('signup_audit_logs')
    .where('ip_address', '==', ipAddress)
    .where(
      'created_at',
      '>=',
      admin.firestore.Timestamp.fromMillis(Date.now() - 15 * 60 * 1000),
    )
    .get();
  return snapshot.size;
}

function safeError(status, code, message) {
  return {
    status,
    body: {
      error: {
        code,
        message,
      },
    },
  };
}

async function completeRestrictedSignup(req, res) {
  try {
    if (req.method !== 'POST') {
      res.status(405).json(safeError(405, 'method_not_allowed', 'Use POST.').body);
      return;
    }

    const { auth, appCheck } = await verifyRequestContext(req);
    const body = requireObject(req.body, 'body');
    const installationId = requireString(body.installation_id, 'installation_id', 256);
    const displayName = requireString(body.display_name, 'display_name', 120);
    const email = requireString(body.email, 'email', 256);
    const platform = requireString(body.platform, 'platform', 32);
    const appVersion = requireString(body.app_version, 'app_version', 64);
    const buildNumber = requireString(body.build_number, 'build_number', 32);
    const requestNonce = requireString(body.request_nonce, 'request_nonce', 128);
    const requestTimestampMs = requireTimestamp(
      body.request_timestamp_ms,
      'request_timestamp_ms',
    );
    const riskSignals = requireObject(body.risk_signals || {}, 'risk_signals');
    const ipAddress = getIpAddress(req);
    const installationIdHash = installationHash(installationId);

    await ensureFreshNonce({
      uid: auth.uid,
      nonce: requestNonce,
      timestampMs: requestTimestampMs,
    });
    await Promise.all([
      incrementRateLimit(`ip:${ipAddress}`, 10, 15),
      incrementRateLimit(`uid:${auth.uid}`, 4, 15),
      incrementRateLimit(`installation:${installationIdHash}`, 4, 60),
    ]);

    const existingInstallationRef = db
      .collection('device_installations')
      .doc(installationIdHash);
    const existingInstallation = await existingInstallationRef.get();
    const ipAttemptCount = await countRecentAttempts(ipAddress);
    const risk = scoreRisk({
      riskSignals,
      appCheck,
      existingInstallation: existingInstallation.exists,
      ipAttemptCount,
    });

    const auditRef = db.collection('signup_audit_logs').doc();
    const auditRecord = {
      uid: auth.uid,
      email,
      installation_id_hash: installationIdHash,
      app_check_app_id: appCheck.appId || null,
      app_check_token_status: 'VERIFIED',
      decision: risk.decision,
      risk_score: risk.score,
      risk_flags: risk.flags,
      ip_address: ipAddress,
      platform,
      app_version: appVersion,
      build_number: buildNumber,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (existingInstallation.exists) {
      await auditRef.set({
        ...auditRecord,
        reason: 'installation_already_registered',
      });
      res.status(409).json({
        error: {
          code: 'installation_already_registered',
          message:
            'This app installation already created an account. Request an admin review if this is a legitimate recovery case.',
        },
      });
      return;
    }

    if (risk.decision === 'BLOCK') {
      await auditRef.set({
        ...auditRecord,
        reason: 'risk_threshold_block',
      });
      res.status(403).json({
        error: {
          code: 'signup_blocked',
          message: 'Signup was blocked by backend risk controls.',
        },
      });
      return;
    }

    if (risk.decision === 'REQUIRE_VERIFICATION') {
      await auditRef.set({
        ...auditRecord,
        reason: 'extra_verification_required',
      });
      await db.collection('account_recovery_requests').add({
        uid: auth.uid,
        installation_id_hash: installationIdHash,
        status: 'PENDING_VERIFICATION',
        risk_score: risk.score,
        risk_flags: risk.flags,
        platform,
        app_version: appVersion,
        build_number: buildNumber,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      res.status(422).json({
        error: {
          code: 'extra_verification_required',
          message:
            'This installation requires additional verification before signup can proceed.',
        },
      });
      return;
    }

    await db.runTransaction(async (tx) => {
      const existingDoc = await tx.get(existingInstallationRef);
      if (existingDoc.exists) {
        throw new HttpsError(
          'already-exists',
          'This installation already has an account.',
        );
      }

      tx.set(existingInstallationRef, {
        installation_id_hash: installationIdHash,
        account_id: auth.uid,
        first_seen_at: admin.firestore.FieldValue.serverTimestamp(),
        last_seen_at: admin.firestore.FieldValue.serverTimestamp(),
        status: 'ACTIVE',
        risk_score: risk.score,
        risk_flags: risk.flags,
        platform,
        app_version: appVersion,
        build_number: buildNumber,
        app_check_status: 'VERIFIED',
      });

      tx.set(db.collection('users').doc(auth.uid), {
        uid: auth.uid,
        email,
        display_name: displayName,
        signup_decision: 'ALLOW',
        signup_installation_id_hash: installationIdHash,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      tx.set(auditRef, {
        ...auditRecord,
        reason: 'signup_allowed',
      });
    });

    res.status(200).json({
      account_id: auth.uid,
      decision: 'ALLOW',
      message: 'Signup allowed and installation linked successfully.',
      review_requested: false,
    });
  } catch (error) {
    handleError(error, res);
  }
}

async function requestDeviceOverride(req, res) {
  try {
    if (req.method !== 'POST') {
      res.status(405).json(safeError(405, 'method_not_allowed', 'Use POST.').body);
      return;
    }

    const { auth } = await verifyRequestContext(req);
    const body = requireObject(req.body, 'body');
    const installationId = requireString(body.installation_id, 'installation_id', 256);
    const reason = requireString(body.reason, 'reason', 500);
    const platform = requireString(body.platform, 'platform', 32);
    const appVersion = requireString(body.app_version, 'app_version', 64);
    const buildNumber = requireString(body.build_number, 'build_number', 32);
    const requestNonce = requireString(body.request_nonce, 'request_nonce', 128);
    const requestTimestampMs = requireTimestamp(
      body.request_timestamp_ms,
      'request_timestamp_ms',
    );
    const riskSignals = requireObject(body.risk_signals || {}, 'risk_signals');
    const installationIdHash = installationHash(installationId);

    await ensureFreshNonce({
      uid: auth.uid,
      nonce: requestNonce,
      timestampMs: requestTimestampMs,
    });

    await db.collection('account_recovery_requests').add({
      uid: auth.uid,
      installation_id_hash: installationIdHash,
      reason,
      status: 'PENDING_REVIEW',
      platform,
      app_version: appVersion,
      build_number: buildNumber,
      risk_signals: riskSignals,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(202).json({
      status: 'queued',
      message: 'Manual device review request queued.',
    });
  } catch (error) {
    handleError(error, res);
  }
}

function handleError(error, res) {
  if (error instanceof HttpsError) {
    const mapping = {
      unauthenticated: 401,
      'failed-precondition': 412,
      'invalid-argument': 400,
      'deadline-exceeded': 408,
      'already-exists': 409,
      'resource-exhausted': 429,
      'permission-denied': 403,
    };
    const status = mapping[error.code] || 500;
    res.status(status).json({
      error: {
        code: error.code.replace(/-/g, '_'),
        message: error.message,
      },
    });
    return;
  }

  console.error('secure_signup_unhandled_error', error);
  res.status(500).json({
    error: {
      code: 'internal_error',
      message: 'Internal signup error.',
    },
  });
}

module.exports = {
  completeRestrictedSignup,
  requestDeviceOverride,
};
