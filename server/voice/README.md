# PhytoSense natural voice gateway

Status: implementation provided; not deployed or activated. No ElevenLabs credentials were available during development. The Android install build truthfully labels its fallback as Phone voice.

This service converts the app's farmer-language explanation into ElevenLabs speech. It does not generate plant diagnoses, change ESP32 advice, infer watering quantities, or merge data sources. Text is sent only after the user enables cloud voice in Voice guidance.

## Activate securely

1. Select and audition licensed English and Tamil voices in your ElevenLabs account. Use a plan/license suitable for commercial distribution. Test Tamil pronunciation with actual farmer guidance before release.
2. Deploy this directory to a Node 22 container host such as Cloud Run, using an application service account for the same Firebase project. Enable Firestore and allow the service account to read/write only the voiceUsage collection. Existing Realtime Database behavior is not modified. Deny direct client access to voiceUsage in Firestore rules.
3. Configure GOOGLE_CLOUD_PROJECT, ELEVENLABS_ENGLISH_VOICE_ID, ELEVENLABS_TAMIL_VOICE_ID, and VOICE_ALLOWED_UIDS (comma-separated Firebase UIDs). This closed pilot deliberately denies all users until explicitly enabled. A public launch needs a reviewed enrollment policy and App Check.
4. Inject ELEVENLABS_API_KEY from your host's secret manager. Never put it in Dart, Gradle, assets, git, or a build argument. Set a spending limit in ElevenLabs as well.
5. Build Flutter with --dart-define=PHYTO_VOICE_ENDPOINT=https://YOUR-DEPLOYMENT/speak. Configure the corresponding GitHub repository variable PHYTO_VOICE_ENDPOINT to use CI. This URL is public configuration; the API key remains on the server.
6. In app Settings > Voice guidance, enable cloud voice and test the sample. Verify denial, daily limits, network loss, replay, and stop on both Android phones. A failed cloud request visibly falls back to phone voice.

Fixed caps: 1,800 characters/request, 10,000/day per UID, 100,000/day globally. Usage is stored in atomic Firestore transactions. Enable Firestore TTL on expires. Advice text and audio are not stored by this gateway. Provider retention is governed by your ElevenLabs account settings.

Run `npm test` for request and budget policy tests. Deployment and live audio quality are unverified until account setup is complete.
