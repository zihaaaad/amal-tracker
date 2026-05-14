# As-Sunnah Amal Tracker

![Build Status](https://github.com/zihaaaad/amal-tracker/actions/workflows/build_release.yml/badge.svg)
![Version](https://img.shields.io/badge/version-1.0.0-2D5A27)
![Platform](https://img.shields.io/badge/platform-Android-blue)

A production-grade, institutional spiritual productivity platform engineered for the **As-Sunnah Foundation**. This monorepo delivers a dual-application ecosystem (Client & Admin) designed to foster spiritual excellence through data-driven tracking, professional oversight, and high-end "Zen" design principles.

## 🏛️ Project Architecture

The platform is architected as a **Symmetrical Monorepo**, sharing a hardened core while delivering two specialized binaries:

### 1. Amal Tracker (Employee Client)
*   **Target**: Spiritual growth and habit tracking for foundation employees.
*   **ID**: `com.amaltracker.app`
*   **Highlights**: Local-first synchronization, "Zen" sensory layer, and personal analytics.
*   **Build**: `flutter build apk --flavor client -t lib/main_client.dart`

### 2. Foundation Admin (Management)
*   **Target**: Institutional oversight and organizational analytics.
*   **ID**: `com.amaltracker.admin`
*   **Highlights**: Biometric-gated access, departmental audits, and global announcements.
*   **Build**: `flutter build apk --flavor admin -t lib/main_admin.dart`

## 💎 Key Features

*   **Institutional Design**: Bespoke "Modern-Classic" aesthetic using a Slate & Forest Green palette.
*   **Globalization**: Full support for English, Bengali (বাংলা), and Arabic (العربية) with native RTL support.
*   **Offline-First Reliability**: Powered by Isar Database with atomic background synchronization to Supabase.
*   **Hardened Security**: Role-based access control (RBAC) and biometric hardware gates for administrative data.
*   **Automated Pipeline**: GitHub Actions CI/CD for simultaneous multi-target APK generation.

## 🚀 Getting Started

### 1. Environment Setup
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2. Development Execution
*   **Client**: `flutter run --flavor client -t lib/main_client.dart`
*   **Admin**: `flutter run --flavor admin -t lib/main_admin.dart`

## 📦 Deployment

Production binaries are automatically generated and released via GitHub Actions.
*   **Artifacts**: `Amal_Tracker_Client.apk` and `Amal_Tracker_Admin.apk`.
*   **Location**: Check the [Releases](https://github.com/zihaaaad/amal-tracker/releases) section for the latest institutional builds.

---
*Developed for the As-Sunnah Foundation. Designed for excellence.*
