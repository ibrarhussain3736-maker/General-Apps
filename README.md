# Toolbox Vault

Offline all-in-one Android app. No internet permission, no ads.

- **Encrypted vault**: AES-256-GCM, PIN + fingerprint unlock, fake PIN with decoy vault, auto-lock
- **Password generator** with strength meter
- **QR generator** and **QR scanner** (with torch)
- **Notes**
- Material 3 UI, dark / AMOLED mode, accent colors

## Get the APK
1. Push this repo to GitHub (include the `.github` folder).
2. Open **Actions**, then the latest **Build APK** run.
3. Download **toolbox-vault-apk** from Artifacts, unzip, install `app-release.apk`.

## Notes
- Keys live in the Android Keystore. Uninstalling the app or clearing its data permanently deletes the vault.
- Backups are disabled on purpose so encrypted files can't be restored without their keys.
- Files are encrypted in memory; very large videos (hundreds of MB) can be slow.
