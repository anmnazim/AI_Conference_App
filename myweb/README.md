# Conference Paper Submission System

Flutter project with **Web Admin Panel** and **Mobile App** (Android / iOS) for an academic conference paper submission system, using Firebase (Auth, Firestore, Storage).

---

## Project structure

| Platform | Entry | Purpose |
|----------|--------|--------|
| **Web** | Admin panel | Login (admin role only), view submissions, Accept/Reject, toggle abstract/full-paper submission, logout |
| **Android / iOS** | User app | **Submit abstract first** (no account), then register to track; login, submit full paper (PDF), view status, real-time feature toggles |

- **Web**: `lib/admin/` — login and dashboard.
- **Mobile**: `lib/app/` — auth, home, submit paper, submission status.
- **Shared**: `lib/models/`, `lib/services/` — Firestore, Auth, Storage, models.

---

## Firebase setup

1. **Firebase project**  
   Use an existing project or create one; ensure **Authentication** (Email/Password **and Anonymous**), **Firestore**, and **Storage** are enabled.  
   **Anonymous** sign-in is used so users can submit an abstract before registering; enable it in Firebase Console → Authentication → Sign-in method → Anonymous.

2. **Admin custom claim**  
   Only users with custom claim `role == 'admin'` can use the web admin panel. Set this with the Firebase Admin SDK (Node.js example):

   ```js
   const admin = require('firebase-admin');
   admin.auth().setCustomUserClaims(uid, { role: 'admin' });
   ```

   Run this (e.g. from a Cloud Function or script) for each admin user after they register.

3. **Firestore rules & indexes**  
   Deploy rules and indexes from the project root:

   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only firestore:indexes
   ```

   Or add Firestore to `firebase.json` and run `firebase deploy --only firestore`.

4. **Initial app settings**  
   Create document `app_settings/settings` in Firestore with:

   - `abstractSubmissionOpen` (boolean)
   - `fullPaperSubmissionOpen` (boolean)

   Example: `{ "abstractSubmissionOpen": true, "fullPaperSubmissionOpen": true }`

5. **Reference number counter**  
   The app uses Firestore document `counters/submission_ref` with field `lastNumber` (number) for sequential reference numbers (UCCICON26-01, 02, …). The first submission will create it; no manual creation required.

---

## Running the app

- **Web (admin)**  
  `flutter run -d chrome`  
  Opens the admin login; only accounts with `role: 'admin'` can access the dashboard.

- **Mobile (user)**  
  `flutter run` (with device/emulator) or `flutter run -d <device_id>`  
  Opens the **welcome screen**: primary action is **Submit Abstract**; then **Register** or **Login**. Submitting an abstract uses anonymous auth; after success the user is prompted to create an account (linking keeps the same submission).

---

## Features

### Web Admin Panel

- Login with email/password; access only if custom claim `role == 'admin'`.
- Dashboard: list of submissions with reference number, title, user name, status (pending/accepted/rejected), optional timestamp.
- Accept / Reject per submission; status updates in Firestore and reflects in the mobile app in real time.
- Feature toggles from `app_settings/settings`: **Abstract submission**, **Full paper submission**. Changes apply in real time for students.
- Search/filter submissions by reference or title; filter by status.
- Logout.

### Mobile App (Android / iOS)

- **Flow: Submit abstract first, then register.** Welcome screen offers **Submit Abstract** (primary), **Register**, and **Login**. Tapping Submit Abstract signs in anonymously (if needed) and opens the abstract submission form. After a successful submit, the user is prompted to **Create account** to track the submission; registering links the anonymous account so the submission stays with their profile.
- **Auth**: Register (name, email, phone, user type: student/scholar) and login; profile stored in `users` collection. Anonymous users can link to email/password when they register.
- **Feature control**: Reads `app_settings/settings`; shows/hides abstract and full-paper submission based on toggles. If disabled, shows “Submission is currently closed by the admin.”
- **Submissions**: PDF only; abstract and full-paper submission types. PDFs stored in Firebase Storage; metadata and extracted text (placeholder) in Firestore.
- **Reference numbers**: Sequential (UCCICON26-01, 02, …), stored with each submission and shown on the user’s submission status screen.
- **Status**: User sees all their submissions with reference number, type, status (Pending/Accepted/Rejected), optional timestamp; updates in real time when admin accepts/rejects.
- **Logout** from the home screen.

---

## Firestore data shape

- **users**  
  `uid`, `name`, `email`, `phone`, `role` (student | scholar).

- **submissions**  
  `uid`, `referenceNumber`, `title`, `pdfUrl`, `extractedText`, `status` (pending | accepted | rejected), `submissionType` (abstract | fullpaper), `createdAt`.

- **app_settings/settings**  
  `abstractSubmissionOpen`, `fullPaperSubmissionOpen` (booleans).

- **counters/submission_ref**  
  `lastNumber` (number) for generating reference numbers.

---

## Optional: PDF text extraction & notifications

- **PDF text extraction**  
  The app stores `extractedText` in Firestore; the current code uses a placeholder. For production, use a Cloud Function (or other backend) that is triggered on new PDF uploads, extracts text, and updates the submission document.

- **Notifications**  
  For “submission accepted/rejected” alerts, add Firebase Cloud Messaging (FCM) and trigger notifications from a Cloud Function when submission status is updated, or use in-app alerts (already reflected by real-time status in the app).

---

## Security summary

- **Firestore rules**: Users read/write only their own `users` and `submissions` docs; admin (via custom claim) can read/write all submissions and app_settings. App settings are readable by any authenticated user; only admin can write. Counters are readable/writable by authenticated users for reference-number generation.
- **Admin panel**: Only users with custom claim `role == 'admin'` can use the web admin flow; others are signed out and shown an error.

---

## Dependencies

- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- `file_picker` (mobile PDF pick), `intl` (formatting)

Generate platform-specific config with FlutterFire CLI: `flutterfire configure`.
