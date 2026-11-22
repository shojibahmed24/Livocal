# Security Policy

## Supported versions

Only the latest code on the `main` branch is supported with security fixes.

## Reporting a vulnerability

Please **do not open a public GitHub issue** for security problems.

Email **support@livocal.app** with:

- a short description of the issue,
- steps to reproduce,
- affected platform/version,
- any proof-of-concept (do not include real user data).

We aim to acknowledge reports within 72 hours and to ship a fix or mitigation
as soon as the report is validated. Please allow us reasonable time to
investigate before any public disclosure.

## Scope

In scope: authentication, Firestore/Storage access rules, the Node.js relay,
WebRTC signalling, wallet/billing logic, and the Flutter client.

Out of scope: reports requiring physical access to an unlocked device,
social-engineering of users, or third-party services (Firebase, Google Gemini,
Render, TURN providers) outside this repository.
