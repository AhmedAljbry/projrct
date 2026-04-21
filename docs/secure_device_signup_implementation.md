Objective

Implement a production-grade, privacy-respecting account creation restriction flow for Flutter + Firebase where one app installation is allowed to create one account, with Firebase App Check attestation, Firebase Installation ID usage, backend enforcement, review tooling, and layered abuse controls.

Plan

1. Bootstrap Firebase and Firebase App Check safely at app startup without breaking the rest of the app when runtime configuration is missing.
2. Add a clean-architecture Flutter signup feature that retrieves Firebase Installation ID, gathers non-privileged risk signals, creates Firebase Auth users, and submits attested signup requests to the backend.
3. Enforce installation uniqueness on the backend with Firebase Auth verification, App Check verification, installation hash storage, replay protection, rate limiting, audit logs, and admin recovery requests.
4. Keep Firestore deny-by-default for sensitive collections and document the operational limitations clearly.

Execution

1. Added `FirebaseBootstrapper` and runtime Firebase options driven by `--dart-define` values so the app remains safe when Firebase is not configured.
2. Added a `secure_signup` feature with:
   - installation ID abstraction
   - App Check and Auth token collection
   - request/response models
   - repository/use cases
   - Cubit state handling
   - signup UI with graceful rejection and manual review request flow
3. Added Android and iOS method-channel risk signals for emulator, root/jailbreak, and debuggable state without using IMEI, serial number, or privileged hardware identifiers.
4. Added Firebase Functions HTTP endpoints for signup completion and manual override requests.
5. Added Firestore rules for the new collections so sensitive backend-only data is never writable or readable by clients.

Output

1) Security architecture

- Client:
  - Initializes Firebase and App Check.
  - Reads Firebase Installation ID through `firebase_app_installations`.
  - Creates the Firebase Auth user.
  - Collects Firebase ID token and App Check token.
  - Sends attested signup payload to the backend.
- Backend:
  - Verifies Firebase Auth ID token separately.
  - Verifies Firebase App Check token separately.
  - Hashes the installation ID with a server-side pepper before persistence.
  - Rejects any second signup from the same installation hash.
  - Applies nonce replay protection, IP/UID/installation rate limits, and risk scoring.
- Data:
  - `device_installations/{installation_id_hash}` is the source of truth for one-installation-to-one-account.
  - `signup_audit_logs` tracks every decision.
  - `account_recovery_requests` supports legitimate recovery and admin override workflows.

2) File-by-file implementation map

- Flutter bootstrap:
  - `C:\Users\MK\StudioProjects\untitled2\lib\core\firebase\firebase_bootstrap.dart`
  - `C:\Users\MK\StudioProjects\untitled2\lib\core\firebase\firebase_runtime_options.dart`
- App config and failures:
  - `C:\Users\MK\StudioProjects\untitled2\lib\core\config\app_config.dart`
  - `C:\Users\MK\StudioProjects\untitled2\lib\core\error\failure.dart`
- Flutter secure signup feature:
  - `C:\Users\MK\StudioProjects\untitled2\lib\features\secure_signup\data\services\firebase_installation_identity_service.dart`
  - `C:\Users\MK\StudioProjects\untitled2\lib\features\secure_signup\data\services\firebase_signup_attestation_service.dart`
  - `C:\Users\MK\StudioProjects\untitled2\lib\features\secure_signup\data\services\method_channel_platform_security_signal_service.dart`
  - `C:\Users\MK\StudioProjects\untitled2\lib\features\secure_signup\data\datasources\restricted_signup_remote_data_source.dart`
  - `C:\Users\MK\StudioProjects\untitled2\lib\features\secure_signup\data\repositories\restricted_signup_repository_impl.dart`
  - `C:\Users\MK\StudioProjects\untitled2\lib\features\secure_signup\domain\usecases\create_restricted_account_use_case.dart`
  - `C:\Users\MK\StudioProjects\untitled2\lib\features\secure_signup\domain\usecases\request_signup_override_use_case.dart`
  - `C:\Users\MK\StudioProjects\untitled2\lib\features\secure_signup\presentation\cubit\restricted_signup_cubit.dart`
  - `C:\Users\MK\StudioProjects\untitled2\lib\features\secure_signup\presentation\pages\restricted_signup_page.dart`
- Flutter integration:
  - `C:\Users\MK\StudioProjects\untitled2\lib\main.dart`
  - `C:\Users\MK\StudioProjects\untitled2\android\app\src\main\kotlin\com\example\untitled2\MainActivity.kt`
  - `C:\Users\MK\StudioProjects\untitled2\ios\Runner\AppDelegate.swift`
- Backend:
  - `C:\Users\MK\StudioProjects\untitled2\modules\coins_system\firebase_backend\functions\src\services\device_signup_service.js`
  - `C:\Users\MK\StudioProjects\untitled2\modules\coins_system\firebase_backend\functions\src\index.js`
  - `C:\Users\MK\StudioProjects\untitled2\modules\coins_system\firebase_backend\firestore.rules`

3) Flutter code

- Firebase initialization:
  - `FirebaseBootstrapper.initialize()` initializes `Firebase.initializeApp(...)` only when runtime options are present and then activates App Check using:
    - Android release: `AndroidProvider.playIntegrity`
    - Android debug: `AndroidProvider.debug`
    - Apple release-ready path: `AppleProvider.appAttestWithDeviceCheckFallback`
    - Apple debug: `AppleProvider.debug`
- Installation ID abstraction:
  - `InstallationIdentityService` is the abstraction.
  - `FirebaseInstallationIdentityService` is the production implementation using `FirebaseAppInstallations.instance.getId()`.
- API request model:
  - `RestrictedSignupApiRequest` carries:
    - `installation_id`
    - `platform`
    - `app_version`
    - `build_number`
    - `display_name`
    - `email`
    - `request_nonce`
    - `request_timestamp_ms`
    - `risk_signals`
- Signup flow integration:
  - `RestrictedSignupRepositoryImpl.signUp(...)` orchestrates:
    - Firebase Installations lookup
    - Firebase Auth user creation
    - App Check token retrieval
    - secure backend call
    - best-effort rollback of newly created auth users if the backend rejects the attempt
- Failure states and user messages:
  - `DeviceAlreadyUsedFailure`
  - `VerificationRequiredFailure`
  - `SecurityRejectedFailure`
  - `FirebaseConfigurationFailure`
  - `ValidationFailure`
  - `NetworkFailure`
- UI:
  - `RestrictedSignupPage` shows:
    - safe configuration hint if Firebase/backend values are missing
    - success message when the installation is linked
    - rejection message when installation reuse is blocked
    - extra verification state
    - admin review request form

4) Backend code

- Middleware example:
  - `verifyRequestContext(req)` verifies:
    - Firebase Auth ID token from `Authorization: Bearer <token>`
    - Firebase App Check token from `X-Firebase-AppCheck`
- Signup endpoint example:
  - `completeRestrictedSignup(req, res)`:
    - validates request body
    - verifies nonce freshness
    - rate limits IP, UID, and installation hash
    - computes installation hash
    - checks if installation already exists
    - scores risk
    - blocks, escalates, or allows
    - persists `device_installations` mapping on allow
- Validation logic:
  - strict type validation for all required fields
  - 5-minute timestamp skew window
  - nonce uniqueness via `request_nonces`
  - installation hash uniqueness via Firestore transaction
- Rejection/error model:
  - `409 installation_already_registered`
  - `403 signup_blocked`
  - `412 failed_precondition` for missing or failed App Check
  - `422 extra_verification_required`
  - `429 resource_exhausted`
- Audit logging model:
  - `signup_audit_logs` stores:
    - `uid`
    - `email`
    - `installation_id_hash`
    - `app_check_app_id`
    - `app_check_token_status`
    - `decision`
    - `risk_score`
    - `risk_flags`
    - `ip_address`
    - `platform`
    - `app_version`
    - `build_number`
    - `created_at`

5) Firebase setup steps

1. Run `flutterfire configure` or provide equivalent `--dart-define` values for:
   - `FIREBASE_ANDROID_API_KEY`
   - `FIREBASE_ANDROID_APP_ID`
   - `FIREBASE_ANDROID_MESSAGING_SENDER_ID`
   - `FIREBASE_ANDROID_PROJECT_ID`
   - `FIREBASE_ANDROID_STORAGE_BUCKET`
   - `FIREBASE_IOS_API_KEY`
   - `FIREBASE_IOS_APP_ID`
   - `FIREBASE_IOS_MESSAGING_SENDER_ID`
   - `FIREBASE_IOS_PROJECT_ID`
   - `FIREBASE_IOS_STORAGE_BUCKET`
   - `FIREBASE_IOS_BUNDLE_ID`
   - `SECURE_SIGNUP_BASE_URL`
2. In Firebase Console, enable Authentication:
   - Sign-in method: Email/Password
   - Optional but recommended: email verification
3. In Firebase Console, enable App Check:
   - Android app:
     - register Play Integrity provider
     - keep debug tokens only for development
   - Apple app:
     - prepare App Attest / DeviceCheck for later rollout
4. In Firebase Console, enable Firestore in production mode.
5. Deploy Functions and Firestore rules:
   - deploy `modules/coins_system/firebase_backend/functions`
   - deploy `modules/coins_system/firebase_backend/firestore.rules`
6. Set function secret/environment value:
   - `INSTALLATION_HASH_PEPPER`
7. Confirm deny-by-default posture:
   - `device_installations`, `signup_rate_limits`, `signup_audit_logs`, `request_nonces`, and `account_recovery_requests` must stay backend-only.

Security Rules example:

```firestore
match /device_installations/{installationIdHash} {
  allow read, write: if false;
}

match /signup_audit_logs/{logId} {
  allow read, write: if false;
}
```

6) DB schema

Primary collection: `device_installations`

- `installation_id_hash`: string
- `account_id`: string
- `first_seen_at`: timestamp
- `last_seen_at`: timestamp
- `status`: string
- `risk_score`: number
- `risk_flags`: array<string>
- `platform`: string
- `app_version`: string
- `build_number`: string
- `app_check_status`: string

Supporting collections:

- `signup_audit_logs`
- `signup_rate_limits`
- `request_nonces`
- `account_recovery_requests`

Hashing strategy and lookup strategy:

- Do not store raw Firebase Installation ID in Firestore.
- Store `sha256(server_pepper + "|" + installation_id)` as the durable lookup key.
- Why:
  - protects the raw app-scoped identifier at rest
  - still allows exact-match uniqueness lookup
  - keeps lookup cheap by using the hash as the document ID
- The server-side pepper must be stored only in function secrets or environment config, never in Flutter code.

7) Failure handling

- Low risk:
  - backend decision `ALLOW`
  - create account mapping
  - return success
- Medium risk:
  - backend decision `REQUIRE_VERIFICATION`
  - do not create installation mapping
  - return safe `422`
  - create `account_recovery_requests` entry for review
- High risk:
  - backend decision `BLOCK`
  - return safe `403`
  - write audit log
- Installation already used:
  - return `409`
  - show user-friendly message
  - expose manual review button

8) Abuse monitoring

- Signals captured today:
  - App Check verification status
  - root/jailbreak heuristic
  - emulator heuristic
  - debug build signal
  - IP velocity
  - repeated installation attempts
- Recommended next monitoring additions:
  - dashboards for:
    - signups per IP / hour
    - App Check failure rate
    - repeated `installation_already_registered`
    - verification-required rate
  - alert when:
    - one IP exceeds safe threshold
    - App Check failures spike
    - manual review queue grows unusually fast
- Additional recommended controls:
  - require verified email before granting full access
  - optionally require phone verification or stronger KYC for high-value flows
  - use Remote Config to tighten thresholds during active abuse windows

9) Limitations

- Firebase Installation ID is app-scoped and privacy-respecting, but it is not permanent.
- FID can change on reinstall, app data clear, backup/restore edge cases, or installation reset scenarios.
- Because of that, this is not a perfect one-physical-device guarantee.
- A determined attacker can still bypass by:
  - reinstalling / clearing app data
  - using device farms or multiple virtual devices
  - tampering with rooted devices
  - abusing stolen verified accounts
- App Check materially raises cost, but it does not eliminate abuse by itself.
- This implementation reduces abuse; it does not provide fake guarantees.
- No IMEI, serial number, phone serial, or other privileged hardware identifier is used.

10) Final checklist

- [x] No IMEI
- [x] No serial number
- [x] No privileged hardware identifier dependence
- [x] Firebase App Check integrated
- [x] Firebase Installation ID used as primary app-installation identifier
- [x] Backend verifies App Check
- [x] Backend verifies Firebase Auth separately
- [x] Installation uniqueness enforced server-side
- [x] Installation ID stored as server-peppered hash
- [x] Manual review / admin override request flow added
- [x] Rate limiting and replay protection added
- [x] Audit logging and monitoring hooks added
- [x] Limitations documented clearly

Review

This implementation is production-oriented and privacy-respecting, but it still depends on correct Firebase Console setup, function secret management, and operational review workflows. The strongest remaining gap is that Firebase Installation ID can be reset, so this should be treated as layered anti-abuse control rather than a hard identity guarantee.
