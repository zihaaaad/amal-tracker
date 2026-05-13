# System Architecture - Amal Tracker

This document provides a detailed overview of the design decisions and technical stack chosen for the Amal Tracker Institutional Edition.

---

## 🏛️ Overall Pattern: Layered Feature-First

The application is structured into four distinct layers to promote high cohesion and low coupling:

1.  **Core Layer (`lib/core`):** Contains the "skeleton" of the app. Infrastructure, themes, and global services.
2.  **Feature Layer (`lib/features`):** Each folder contains its own data, providers, and presentation logic. Features are modular.
3.  **Shared Layer (`lib/shared`):** Universal UI components and models used across multiple features.
4.  **Main Layer:** The entry point and global routing.

---

## 💾 Data Management Strategy

### Hybrid Local-Cloud (Isar + Supabase)
We use a "Local-First" synchronization model:
-   **Isar** acts as the Source of Truth (SoT) for the user interface.
-   **Supabase** acts as the remote persistence and synchronization layer.
-   **Why?** This ensures the app is 100% functional in poor network conditions (common during travel or in mosques) while keeping data safe in the cloud.

### Conflict Resolution
We implement a **Last-Write-Wins (LWW)** strategy using `updated_at` timestamps.
-   Before a local record is pushed to the cloud, we compare timestamps.
-   This prevents older data from a secondary device from overwriting fresh data on the primary device.

---

## 🎨 Design System

Our UI is built on a **Custom Theme Extension** system. This allows us to access brand-specific properties directly from `BuildContext`.

-   **Semantic Colors:** Instead of generic `primaryColor`, we use `timeTint` (dynamic based on time of day) and `surfaceCard`.
-   **Micro-Interactions:** Every button press uses `HapticFeedback` to provide physical weight to the digital experience.
-   **Typography:** We use **Outfit** for headings to provide a modern, premium feel, and standard sans-serif for body text for readability.

---

## 🔒 Security Gatekeeping

-   **Client-Side:** The `AdminDashboardScreen` requires biometric authentication before instantiation.
-   **Server-Side:** Supabase **Row Level Security (RLS)** prevents users from reading logs belonging to others, while allowing authorized admins to see department-wide metrics.

**Document Version:** 1.0.0
**Lead Engineer:** Antigravity (AI Architect)
