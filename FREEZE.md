# PhytoSense AI final release freeze

This branch is frozen for the final Uptodown release. Changes after this point
must be limited to verified defect or security fixes and must pass the complete
FINAL Uptodown Release workflow before distribution.

The only distributable artifact from the release gate is `PhytoSense-AI.apk`.
Release status remains locked until every workflow gate passes.
Verification is bound to the immutable release commit and its signed APK.
The pull-request head SHA must match the verified artifact provenance.
