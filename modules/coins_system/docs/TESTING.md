# Testing Instructions

## Flutter tests

Run only the new module tests:

```bash
flutter test test/coins_module
```

Recommended manual checks:

1. Sign in on a fresh device and confirm the first account gets 10 coins.
2. Sign out, create another account on the same device, and confirm it gets 0 initial coins.
3. Watch one rewarded ad, confirm backend adds coins once, then retry within 60 seconds and confirm rate limiting.
4. Complete a real Google Play test purchase and confirm duplicate token reuse is rejected.
5. Disable internet or App Check temporarily and confirm the host app does not crash.

## Backend validation checks

1. Call `registerUser` twice with the same nonce and verify replay is blocked.
2. Call `rewardAd` with a modified signature and verify the function rejects it.
3. Send mismatched `deviceHash` or `fingerprintSignature` and confirm an abuse flag is written.
4. Refund or cancel a test order in Google Play Console and ensure `verifyPurchase` does not grant coins for non-completed states.

## Observability

Monitor:

- Cloud Functions logs
- Firestore `abuse_flags`
- Firestore `transactions`
- App Check dashboard
