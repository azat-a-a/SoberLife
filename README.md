# SoberLife PWA (Firebase)

SoberLife is now a web-first Progressive Web App with Firebase as the only backend stack:
- Firebase Authentication
- Cloud Firestore
- Firebase Hosting

## Project Structure

- `public/index.html` - app shell.
- `public/app.js` - UI and Firebase flow (auth, onboarding, streak, community check-in).
- `public/firebase-config.js` - Firebase web config template.
- `public/manifest.webmanifest` - PWA manifest.
- `public/sw.js` - service worker for basic offline caching.
- `firestore.rules` - access control rules.
- `functions/` — Cloud Functions (**`sosDeepseekChat`** → DeepSeek proxy, secret `DEEPSEEK_API_KEY`).
- `firebase.json` - Hosting/Firestore/Storage config.

## Setup

1. Install Firebase CLI:
   - `npm i -g firebase-tools`
2. Login and bind project:
   - `firebase login`
   - `firebase use --add`
3. Update `.firebaserc` with your Firebase project id.
4. Fill `public/firebase-config.js` with values from Firebase Console.

## Local Run

- `npm run start`
- Open `http://localhost:5173`

## Deploy

- `firebase deploy --only hosting,firestore,storage`
- SOS AI (DeepSeek): see `SOS-DEEPSEEK-DEPLOY.md` and `functions/` (callable `sosDeepseekChat`, secret `DEEPSEEK_API_KEY`).

