# Air-Time-Manager

MVP Flutter app (RTL Hebrew) with local-first repository + Firebase-ready structure.

## Running (dev container)

In this container Flutter is installed at `/opt/flutter/bin/flutter`.

### Recommended (stable) Web run

Build + serve static output (avoids Codespaces/web-server flakiness):

```bash
./tool/flutter build web --release --base-href /
python3 -m http.server 8080 --directory build/web
```

Open the forwarded port URL.

### Dev Web run (hot reload)

```bash
/opt/flutter/bin/flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

If changes don’t show up in the browser, do a hard refresh (`Ctrl+Shift+R`) or clear site data.

## Firebase

Firebase init is intentionally "safe" and **skipped on Web** until we add proper `FirebaseOptions` (via FlutterFire).

### Phase 2 setup (Auth + Firestore)

This repo contains MVP Firestore config files:

- firebase.json
- firestore.rules
- firestore.indexes.json

To connect a real Firebase project (recommended from your host machine):

1) Install Firebase CLI + FlutterFire CLI.
2) Run `flutterfire configure` to generate `lib/firebase_options.dart`.
3) Remove the temporary “skip on web” logic only after options exist.
4) Deploy rules:

```bash
firebase deploy --only firestore:rules
```

Notes:
- Rules are MVP: any signed-in user (including anonymous) can read/write.
- The app signs in anonymously when Firebase is configured.
