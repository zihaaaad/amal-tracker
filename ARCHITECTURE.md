# System Architecture - Amal Tracker Monorepo

This document details the industrial-grade architectural decisions behind the Amal Tracker Multi-Target platform.

---

## 🏛️ Monorepo Strategy: Shared Kernel, Specialized Targets

The application is engineered as a **Single-Source Monorepo**. We share 95% of the codebase (models, database logic, themes) while branching into two specialized applications at the entry-level.

### 1. The AppCore Kernel (`lib/app_core.dart`)
Instead of a standard `main()`, we use a centralized `AppCore` class that acts as the application's lifecycle manager.
-   **Engine Warm-up:** Handles parallel initialization of Timezones, Isar, and Supabase.
-   **Asset Pre-warming:** Triggers the text rendering pipeline to eliminate jank during the first screen transition.
-   **Global State Awareness:** Tracks whether the current instance is in `client` or `admin` mode.

### 2. Multi-Target Entry Points
-   `main_client.dart`: Initializes the kernel in Client mode. Points to the personal tracker.
-   `main_admin.dart`: Initializes the kernel in Admin mode. Points directly to institutional oversight.

---

## 🔒 Security Gatekeeping & Hard Boundaries

We implement **Defense-in-Depth** for the Admin target:
1.  **Flavor Level:** Distinct Package IDs (`com.amaltracker.admin`) ensure physical separation of data folders on the device.
2.  **App Level:** The `_AppRouter` performs a synchronous check against the `isAdmin` property of the live database profile.
3.  **UI Level:** Biometric authentication (`local_auth`) is required every time the Admin Dashboard is accessed.
4.  **Database Level:** Supabase RLS policies ensure that even if the app was compromised, the raw data remains inaccessible to unauthorized roles.

---

## 💾 Institutional Data Flow

### Atomic Sync Engine
We use a "Local-First" model with Isar as the primary storage. The sync engine is hardened with:
-   **Batch Processing:** Data is synced in chunks of 50 records to prevent payload timeouts.
-   **Conflict Resolution:** Last-Write-Wins (LWW) strategy using nano-precision `updated_at` timestamps.
-   **Sync Results:** The `SyncResult` object provides detailed feedback on success, failure, and network status to the UI.

### Global Analytics Pipeline
The Admin app utilizes a specialized `AdminService` that performs aggregate queries across the `profiles` and `daily_logs` tables to calculate:
-   **Institutional Pulse:** Real-time engagement percentages.
-   **Performance Rankings:** Weighted point calculation over a rolling 7-day window.

---

## 🎨 Professional Design System

Our UI is built on a **Layered Theme Extension** architecture:
-   **Context Awareness:** Colors are resolved via `context.timeTint` or `context.surface`, allowing for dynamic mood shifting based on the spiritual time of day.
-   **Haptic Integration:** The system uses `selectionClick` and `mediumImpact` feedback to provide a tactile "premium" feel consistent with high-end institutional tools.

---

**Document Version:** 2.0.0
**Architect:** Gemini CLI (Senior AI Engineer)
