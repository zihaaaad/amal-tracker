# Amal Tracker - Enterprise Operations Manual

## 📌 Project Overview
Amal Tracker is a professional, institutional-grade application designed for the As-Sunnah Foundation. It utilizes a modern, offline-first architecture to ensure reliability in any connectivity environment.

---

## 🏗️ Technical Architecture

### 1. Database Layer
- **Local (Isar Database):** High-performance local storage for daily logs and task definitions. All schema definitions are located in `lib/core/database/isar_schemas.dart`.
- **Cloud (Supabase):** Handles identity management, global task synchronization, and institutional employee records.
- **Conflict Resolution:** Implements a "Last-Write-Wins" strategy based on `updated_at` timestamps to ensure data integrity during offline/online transitions.

### 2. Security Protocols
- **Admin Access:** Protected by a biometric security gate (`local_auth`). Authentication is required every time the Admin Dashboard is accessed.
- **Data Protection:** Supabase Row Level Security (RLS) ensures employees can only access their own logs while administrators can manage institutional data.

### 3. Notifications Engine
- **Precision Reminders:** Uses `NotificationService` with exact `zonedSchedule` for Fajr, Evening Check, and Sleep reminders.
- **Background Logic:** Uses `Workmanager` for periodic health checks and streak alerts (Rule 5) to minimize battery impact.

---

## 🚀 Deployment Workflow

### 🛠️ Local Development
To run the project locally with full feature support:
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs` (Required for Isar schemas)
3. `flutter run`

### 📦 CI/CD Pipeline (GitHub Actions)
The repository is equipped with a hardened build pipeline in `.github/workflows/build_release.yml`:
- **Automated Validation:** Runs `flutter analyze` and schema generation.
- **Build Output:** Produces a release-ready APK artifact on every push to `main`.
- **Android Hardening:** Automatically handles namespace injection for legacy plugins and forces `compileSdk 36`.

---

## 🔐 Maintenance & Secrets
For Production Play Store deployment, the following GitHub Secrets must be configured:
- `SUPABASE_URL` & `SUPABASE_ANON_KEY`
- `SIGNING_KEY` (Base64)
- `KEY_STORE_PASSWORD`
- `KEY_ALIAS`

---

## 👨‍💻 Support & Scaling
To add new institutional departments:
1. Update the `amal_tasks` table in Supabase.
2. The `AdminDashboardScreen` will automatically reflect changes for all employees via Riverpod's `ref.invalidate(tasksProvider)`.

**Built with excellence by the Amal Tracker Engineering Team.**
