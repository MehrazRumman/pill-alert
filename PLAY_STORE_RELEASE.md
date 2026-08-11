# Google Play release checklist

The Android project targets API 36 and builds an Android App Bundle with release shrinking enabled.

## Before the first upload

- Reserve and confirm the permanent application ID: `com.nirbhor.app`. It cannot be changed after publishing.
- Create the app in Play Console, enroll in Play App Signing, and create a separate upload key. Never commit the key or `keystore.properties`; both are ignored by Git.
- Increase `versionCode` for every subsequent upload and update `versionName` for user-facing releases.
- Build the signed bundle with Android Studio's **Generate Signed Bundle / APK** flow, selecting **Android App Bundle** and the upload key. The output is under `app/build/outputs/bundle/release/`.
- Test the signed bundle through Play's internal testing track on at least Android 8, Android 13, Android 14, Android 15, and Android 16. Verify camera scanning, notification permission, exact-alarm access, full-screen alarm access, reboot rescheduling, PDF sharing, backup/restore, large text, Bangla, and English.

## Play Console declarations

- App category: **Medical**. The app is a medication reminder, not a diagnostic or treatment service.
- Complete the **Health apps declaration** and provide a public privacy-policy URL even though medicine data remains on the device.
- Data safety: the current build has no network permission and does not transmit data off-device. Camera images are processed on-device and temporary capture files are deleted after OCR. Medication data and settings are stored locally; encrypted Android backup may copy them through the user's platform backup service.
- Ads: **No**.
- App access: no account or login is required.
- Content rating: complete the questionnaire truthfully for a medication reminder.
- Target audience: select the actual intended age groups; do not mark the app as child-directed unless the product and store listing are designed for children.
- Declare `USE_FULL_SCREEN_INTENT`. Its use is limited to the core dose-alarm experience and gracefully falls back to a standard high-priority notification when access is unavailable.
- Explain `SCHEDULE_EXACT_ALARM` as necessary for user-created, time-critical medicine reminders. Users explicitly enable special access and an inexact fallback remains available.
- Camera permission purpose: optional on-device OCR of medicine packaging. Manual entry and gallery selection remain available.

## Store assets and listing

- Supply a 512×512 Play icon, 1024×500 feature graphic, phone screenshots, and tablet screenshots if tablets are supported.
- The listing must avoid claims that the app diagnoses, prevents, cures, or guarantees treatment outcomes.
- State clearly that reminders do not replace medical advice and that users should follow their prescriber's instructions.
- Provide a working support email and privacy-policy URL.

## Release gates

Run before every upload:

```sh
./gradlew clean testDebugUnitTest connectedDebugAndroidTest lintRelease bundleRelease
```

Inspect Play Console's pre-launch report, App Bundle Explorer warnings, policy status, and automated device results before promoting beyond internal testing.
