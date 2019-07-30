# Life-time value calculator

An online tool for calculating life-time value of a customer, and comparing
it to cost-per-click expenses. Initially built for AdWords, with data
from [Consumer Barometer][], but the algorithm is broadly usable.

[Consumer Barometer]: https://web.archive.org/web/20190721103027/https://www.consumerbarometer.com/

Methodology is explained in the tool itself.

## Development

The tool is written in pure Dart (not AngularDart nor Flutter) and compiled
to JavaScript. The following instructions assume you have [installed Dart][]
and put it in path.

[installed Dart]: https://dart.dev/get-dart

### Local server

Use `webdev serve` for development. This will show the web app on
`localhost:8080`. If you don't have the `webdev` tool, run 
`pub global activate webdev`.

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
