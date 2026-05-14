# Amal Tracker - Enterprise Operations Manual

This manual provides operational guidance for managing and deploying the Amal Tracker Monorepo ecosystem.

---

## 🏛️ Ecosystem Overview
The Amal Tracker ecosystem consists of two distinct applications sharing a single backend and kernel:
1.  **Amal Tracker (Client):** The daily spiritual tracker for employees.
2.  **Foundation Admin:** The institutional oversight and analytics dashboard for management.

---

## 🏗️ Technical Operations

### 1. The Multi-Target Architecture
The project uses **Targeted Entry Points** and **Build Flavors** to generate independent binaries.
-   **Kernel Init:** All apps boot via `AppCore.init(AppMode mode)`.
-   **Hardware Separation:** Each flavor uses a unique Package ID to ensure separate local storage and preference files.

### 2. Build & Deployment Commands
Use these commands for local development and manual builds:

| Application | Command (Run) | Command (Build APK) |
| :--- | :--- | :--- |
| **Client** | `flutter run --flavor client -t lib/main_client.dart` | `flutter build apk --release --flavor client -t lib/main_client.dart` |
| **Admin** | `flutter run --flavor admin -t lib/main_admin.dart` | `flutter build apk --release --flavor admin -t lib/main_admin.dart` |

---

## 🛡️ Security & Access Control

### Role-Based Access (RBAC)
User roles are managed in the Supabase `profiles` table.
-   **Role: 'employee'** - Can only access the Client app.
-   **Role: 'admin'** - Can access both apps. Access to the Admin app is further gated by a mandatory biometric challenge.

### Institutional Protection
The system uses **Dynamic Auth Redirects**. The Client app redirects to `com.amaltracker.auth`, while the Admin app uses `com.amaltracker.admin.auth`. This prevents cross-app authentication leaks.

---

## 📊 Analytics & Reporting
The Admin Dashboard provides real-time institutional metrics:
-   **Engagement Pulse:** Calculated daily via the `AdminService` by aggregating `daily_logs` completion data.
-   **Top Performers:** A rolling 7-day leaderboard based on cumulative points from prayers and habits.

---

## 🚀 CI/CD Pipeline
The GitHub Actions pipeline (`.github/workflows/build_release.yml`) is the primary deployment method. It automatically:
1.  Performs static analysis.
2.  Generates code for Isar schemas.
3.  Builds **both** the Client and Admin APKs.
4.  Attaches the binaries to the GitHub Release.

---

**Institutional Integrity. Engineering Excellence.**
