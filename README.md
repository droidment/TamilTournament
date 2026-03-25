# Tamil Tournament

Tamil Tournament is a Flutter web app for running a badminton tournament from a single organizer workspace. The current product surface covers organizer sign-in, tournament setup, category and entry management, court management, and match scheduling/scoring backed by Firebase.

## Current Scope

- Flutter web organizer app
- Google sign-in for organizers
- Firestore-backed tournament data
- Scheduling logic for pools and knockout play
- Firebase Hosting deployment

The app is currently configured for web only. Non-web Flutter targets are not set up in `firebase_options.dart`, and the Google sign-in flow explicitly assumes a web runtime.

## Stack

- Flutter
- Dart
- Riverpod
- `go_router`
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase Hosting

## Project Structure

```text
lib/
  app/          App shell and routing
  bootstrap/    Startup and Firebase initialization
  features/     Feature modules such as auth, tournaments, entries, categories, scheduler
  firebase/     Generated FlutterFire config
  shared/       Shared UI and utilities
  theme/        App theme and design tokens

test/
  features/scheduler/  Scheduler domain tests

docs/
  badminton_tournament_scheduler_blueprint.md
  firebase_web_setup.md
  flutter_taste_design_brief.md
```

## Important Entry Points

- App bootstrap: `lib/main.dart`
- Router: `lib/app/router/app_router.dart`
- Organizer sign-in screen: `lib/features/auth/presentation/sign_in_page.dart`
- Firebase config: `lib/firebase/firebase_options.dart`
- Firebase Hosting config: `firebase.json`
- Firestore rules: `firestore.rules`

## Prerequisites

- Flutter SDK installed
- A Chrome browser target for local web runs
- Firebase CLI installed if you plan to deploy

## Local Development

Install dependencies:

```bash
flutter pub get
```

Run the app locally in Chrome:

```bash
flutter run -d chrome
```

Run tests:

```bash
flutter test
```

Build the production web bundle:

```bash
flutter build web
```

## Firebase

This repository already includes generated FlutterFire web configuration for the Firebase project `tamiltournament-e7c59`.

Relevant files:

- `lib/firebase/firebase_options.dart`
- `.firebaserc`
- `firebase.json`
- `firestore.rules`
- `storage.rules`

If you need to rebind the app to a different Firebase project, rerun FlutterFire for the web platform:

```bash
flutterfire configure --project <your-project-id> --platforms web
```

## Deployment

Build the web app first:

```bash
flutter build web
```

Then deploy with Firebase Hosting:

```bash
firebase deploy
```

Hosting is configured to serve `build/web` and rewrite all routes to `index.html`, which matches the app's client-side routing setup.

## Current Limitations

- Web is the only configured platform
- Test coverage is concentrated in scheduler domain logic
- Some planning docs still describe setup work that has already been completed

## Documentation

- Product and scheduling blueprint: `docs/badminton_tournament_scheduler_blueprint.md`
- Firebase notes: `docs/firebase_web_setup.md`
- UI/design brief: `docs/flutter_taste_design_brief.md`
