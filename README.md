# Life-time value calculator


## Development

### Local server

Use `webdev serve` for development. This will show the web app on
`localhost:8080`. If you don't have the `webdev` tool, [install Dart][],
put it in path, then run `pub global activate webdev`.

[install Dart]: https://dart.dev/get-dart

When you're ready to deploy, see build and deploy instructions below.

### Build instructions

To build the frontend and put it onto the App Engine-based backend, run the
following command:

    webdev build -o web:app-engine-backend/static/
    
This compiles the Dart file(s) in `web/` into JavaScript.

#### Testing the app in the App Engine localhost

The app should work exactly the same as it does in `webdev`, but to stay safe,
go to the backend subdirectory (`cd app-engine-backend`) and run
the local App Engine server (`dev_appserver.py .`).

### Deploy instructions

For this and for testing the app locally, you need the [Google Cloud SDK][]
installed.

[Google Cloud SDK]: https://cloud.google.com/sdk/install

Then, just run `gcloud app deploy --project life-time-value` (assuming you
have a Google App Engine project called `life-time-value`).
