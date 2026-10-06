# Project Owner

Project Owner is one Flutter application for web/PWA and Android. Both targets
use the same controller, repository contracts, and Dio API service. When an API
URL is configured, Laravel is the source of truth; the in-memory mock repository
is used only when no URL is configured (for local UI/testing).

## Run

```sh
flutter pub get
flutter run -d chrome
flutter devices
flutter run -d <android-device>
```

## Laravel API

Point both builds to the same Laravel API URL. The value should include the
`/api/` prefix and be reachable by both the browser and Android device:

```sh
flutter run -d chrome --dart-define=API_BASE_URL=https://api.example.com/api/
flutter run -d <android-device> --dart-define=API_BASE_URL=https://api.example.com/api/
```

The shared `ApiService` calls `GET /projects`, `GET /projects/{id}`,
`POST /projects`, `PUT /projects/{id}`, and `DELETE /projects/{id}`. It accepts
Laravel resource responses (`{ "data": [...] }` / `{ "data": {...} }`) or a
plain JSON array/object. Project payloads contain `name`, `client`, `status`,
and `progress`. The shared `AuthRepository` calls `POST /login` with `email`
and `password`, expects a `token` and `owner`, and installs the token as a
`Bearer` header on the same API service for subsequent requests.

With no `API_BASE_URL`, the seeded in-memory mock keeps the existing UI usable;
it is not a cross-device data store and should not be used as production data.
No local database or offline synchronization is used. When connected, refresh
or reopening the Projects page fetches the latest API state. Laravel should
enable CORS for the deployed PWA origin and use HTTPS for production.

## Build

```sh
flutter build web
flutter build apk
# or
flutter build appbundle
```

The web build is written to `build/web/`. Serve that directory over HTTPS (or
localhost) to test PWA installation. The manifest and icons are under `web/`;
Flutter generates the web bootstrap and service worker as part of the build.
The shared placeholder logo is `assets/images/app_logo.png`; web icons are under
`web/`, and Android launcher icons are under
`android/app/src/main/res/mipmap-*`.

## Validate

```sh
flutter analyze
flutter test
```
