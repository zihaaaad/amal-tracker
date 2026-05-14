# 🕌 Amal Tracker - Institutional Monorepo

[![Flutter](https://img.shields.io/badge/Flutter-3.41.9-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Isar](https://img.shields.io/badge/Isar-NoSQL-4285F4)](https://isar.dev)
[![Architecture](https://img.shields.io/badge/Arch-Monorepo-orange)](ARCHITECTURE.md)

An industrial-grade, multi-target platform engineered for the **As-Sunnah Foundation**. This repository utilizes a **Monorepo Architecture** to deliver two distinct, secure applications from a single source of truth.

---

## 📱 The Dual-App Ecosystem

This project delivers two specialized applications using **Flutter Flavors** and **Targeted Entry Points**:

### 1. 👥 Amal Tracker (Employee App)
*   **Package ID:** `com.amaltracker.app`
*   **Purpose:** Personal spiritual growth tracking for foundation employees.
*   **Key Features:** Glassmorphic UI, Offline-first tracking, Smart notifications, Personal analytics.
*   **Build:** `flutter build apk --flavor client -t lib/main_client.dart`

### 2. 👑 Foundation Admin (Management App)
*   **Package ID:** `com.amaltracker.admin`
*   **Purpose:** Institutional oversight and task management.
*   **Key Features:** Biometric-gated access, Global participation analytics, Top performer leaderboards, Real-time task distribution.
*   **Build:** `flutter build apk --flavor admin -t lib/main_admin.dart`

---

## 💎 Premium Engineering

-   **🛡️ Hard Security Boundaries:** Role-based access control (RBAC) enforced at both the UI router level and the Database (Supabase RLS).
-   **⚡ AppCore Engine:** A centralized initialization kernel (`AppCore`) that handles timezone logic, Isar hydration, and background service warm-up.
-   **🔄 Atomic Sync Engine:** Hardened sync logic with conflict resolution and chunked upserts for extreme reliability.
-   **📊 Institutional Intel:** Real-time metrics showing organizational "Pulse" and engagement trends.
-   **🎨 Bespoke Design System:** Custom theme extensions for seamless light/dark transitions and haptic feedback integration.

---

## 🏗️ Monorepo Structure

```text
lib/
├── app_core.dart       # The engine kernel (Shared Init/Router)
├── main_client.dart    # Entry point for Employee App
├── main_admin.dart     # Entry point for Admin App
├── core/               # Infrastructure (Database, Auth, Themes)
├── features/           # Domain Logic (Admin, Tracker, Analytics)
└── shared/             # Atomic UI Components
```

---

## 🛠️ Developer Setup

1.  **Clone & Install:**
    ```bash
    git clone https://github.com/zihaaaad/amal-tracker.git
    flutter pub get
    ```
2.  **Generate Assets:**
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
3.  **Run Client:**
    ```bash
    flutter run --flavor client -t lib/main_client.dart
    ```
4.  **Run Admin:**
    ```bash
    flutter run --flavor admin -t lib/main_admin.dart
    ```

---

## 🚢 CI/CD Pipeline
Our GitHub Actions workflow is fully automated to build and release **both APKs simultaneously**. Every push to `main` generates:
*   `Amal_Tracker_Client.apk`
*   `Amal_Tracker_Admin.apk`

---

**Engineered with precision for the As-Sunnah Foundation.**
