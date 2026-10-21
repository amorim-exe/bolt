# ⚡ Bolt

### Your APIs. Your Workflow. Your Speed.

A modern workspace designed to simplify API development, streamline your workflow, and boost your productivity.

<p align="center">
<img src="./assets/images/home2.png" alt="Bolt — Application Preview" width="850">
</p>

<p align="center">
<em>Build faster. Test smarter. Ship with confidence.</em>
</p>

---

## About Bolt

Bolt is a modern, lightweight, and native REST API client built with Flutter for Windows and Linux. Designed as an alternative to resource-heavy Electron-based tools like Postman, Bruno, or Insomnia, it delivers instantaneous startup, minimal RAM consumption, and a distraction-free developer experience.

## Key Features

* **Native Performance:** Developed in Flutter with local binary compilation for Windows and Linux, eliminating heavy Node.js and Electron overhead.
* **Local Workspace & Collections:** Organize requests into folders and workspaces with high-performance local storage powered by Isar.
* **Environment Variables:** Seamlessly manage and apply dynamic variables such as `{{baseUrl}}` across URLs, headers, and request bodies.
* **Dynamic Headers & Query Parameters:** Easily toggle, add, or remove parameters and headers on the fly.
* **Automatic Query Detection:** Query parameters in a request URL appear in the Params editor, including repeated keys, alongside manually added parameters.
* **Collection Transfer:** Import Postman v2.1 and OpenAPI JSON/YAML files or individual Bruno `.bru` requests; export a workspace as a Postman v2.1 collection.
* **Request Authentication:** Configure Bearer tokens, Basic Auth, or API keys in headers or query parameters.
* **Response Preview & Cookies:** Preview image responses and a restricted set of safe HTML formatting; inspect cookies received with the response.
* **Post-Request Assertions:** Add one assertion per line in the request's Tests tab. Supported values include `status`, `responseTimeMs`, `responseSizeBytes`, `statusMessage`, and nested `data` fields, with `==`, `!=`, `<`, `<=`, `>`, and `>=` comparisons. Example: `status == 200` or `responseTimeMs < 1000`.
* **Request Tabs & History:** Keep independent requests open and reload previously dispatched requests from history.
* **Dark & Light Themes:** Fully responsive interface designed to adapt to your development environment preferences.
* **Detailed Response Inspector:** Analyze HTTP status codes, latency in milliseconds, payload size in bytes, formatted JSON payloads, and response headers.

## Built With

* **[Flutter](https://flutter.dev/)** — UI toolkit for building natively compiled applications for desktop.
* **[Riverpod](https://riverpod.dev/)** — Robust and reactive state management architecture.
* **[Dio](https://pub.dev/packages/dio)** — HTTP client featuring interceptors for timing and request handling.
* **[Isar](https://isar.dev/)** — High-performance NoSQL database for local data persistence.
