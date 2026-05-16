# Dependency Manifesto: Amal Tracker Monorepo

This document details the selection and purpose of the primary dependencies used within the As-Sunnah Amal Tracker ecosystem. Every dependency is chosen for its performance, stability, and alignment with our "Local-First" architecture.

## 🏗️ State Management
### Riverpod (v2.6.1)
- **Purpose**: Dependency injection and reactive state management.
- **Selection Criteria**: Compile-time safety, testability, and the ability to handle complex async streams without the overhead of heavy boilerplate.

## 💾 Persistence Layer
### Isar Database (v3.1.0+1)
- **Purpose**: Primary local-first storage.
- **Selection Criteria**: Ultra-low latency reads/writes, asynchronous ACID transactions, and a rich query engine that allows for complex spiritual analytics without blocking the UI thread.

## ☁️ Backend & Infrastructure
### Supabase (v2.9.x)
- **Purpose**: Identity management, institutional role synchronization, and cloud-backups.
- **Selection Criteria**: PostgREST efficiency, Row Level Security (RLS) for institutional privacy, and seamless Google OAuth integration.

### Firebase Messaging (v16.2.x)
- **Purpose**: High-availability server-side "Spiritual Nudges" and announcements.
- **Selection Criteria**: Tier-1 reliability for push notifications and institutional broadcasting.

## 📐 Globalization
### Easy Localization (v3.0.x)
- **Purpose**: Multi-language management and RTL support.
- **Selection Criteria**: Clean asset-based key management and dynamic locale switching without application restarts.

## 🎨 Professional UI/UX
### Google Fonts
- **Purpose**: Bespoke institutional typography (Outfit & Inter).
- **Flutter Animate**
- **Purpose**: High-performance "Zen" micro-interactions.
- **Selection Criteria**: Declarative animation logic that maintains a consistent 60fps frame rate.

---
**Maintained by the As-Sunnah Engineering Team.**
