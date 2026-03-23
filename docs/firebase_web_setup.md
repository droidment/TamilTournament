# Firebase Web Setup

## What I Need From You

I do not need secret API keys up front.

For a Flutter web app using Firebase, the client configuration values are public app configuration, not server secrets. What I do need is:

- the Firebase project ID you want to use
- confirmation that this app should be added as a web app in that Firebase project

## Services Planned

This app is prepared to use:

- Google Auth
- Cloud Firestore
- Cloud Storage
- Firebase Hosting

Target for first release:

- Flutter web only

## Next Firebase Step

Once you choose the Firebase project, I will run:

```bash
flutterfire configure --project <your-project-id> --platforms web
```

That will generate the web Firebase options file used by Flutter.

## Notes

- Firebase web config values are expected to be shipped to the browser.
- Firestore, Storage, and Auth still need proper security rules.
- Hosting is separate from app config. After the app is ready, I will initialize Hosting and wire deploy commands.

## If You Already Know The Project

Send me the Firebase project ID you want for this app and I can bind the scaffold to it next.
