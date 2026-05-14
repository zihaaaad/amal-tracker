# Amal Tracker Institutional Monorepo

This repository contains a multi-target Flutter platform developed for the As-Sunnah Foundation. It utilizes a monorepo architecture to manage both the employee-facing tracking application and the institutional management dashboard from a single codebase.

## Project Structure

The platform is divided into two distinct application targets:

### 1. Amal Tracker (Client)
*   Package ID: `com.amaltracker.app`
*   Target: Employee spiritual growth and daily practice tracking.
*   Features: Local-first data management, automated synchronization, and personal analytics.
*   Build Command: `flutter build apk --flavor client -t lib/main_client.dart`

### 2. Foundation Admin (Dashboard)
*   Package ID: `com.amaltracker.admin`
*   Target: Institutional oversight and resource management.
*   Features: Biometric-gated access, organizational analytics, and task distribution management.
*   Build Command: `flutter build apk --flavor admin -t lib/main_admin.dart`

## Technical Overview

### Core Architecture
*   Kernel Engine: Centralized initialization via the `AppCore` class located in `lib/app_core.dart`.
*   Security: Role-based access control (RBAC) enforced at the application router and database layers.
*   Synchronization: Local-first architecture using Isar Database with background synchronization to Supabase.
*   CI/CD: Automated build pipeline via GitHub Actions for simultaneous APK generation.

### Directory Mapping
```text
lib/
├── app_core.dart       # Central application kernel
├── main_client.dart    # Employee app entry point
├── main_admin.dart     # Admin app entry point
├── core/               # Infrastructure, services, and themes
├── features/           # Domain-specific business logic
└── shared/             # Reusable UI components
```

## Setup and Development

1.  Initialize environment:
    ```bash
    flutter pub get
    ```
2.  Generate data schemas:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
3.  Execute development build:
    *   Client: `flutter run --flavor client -t lib/main_client.dart`
    *   Admin: `flutter run --flavor admin -t lib/main_admin.dart`

## Deployment

The GitHub Actions workflow in `.github/workflows/build_release.yml` automates the release process. Every push to the main branch triggers the generation of two separate APK artifacts:
*   `Amal_Tracker_Client.apk`
*   `Amal_Tracker_Admin.apk`

These are automatically attached to the corresponding GitHub Release.
