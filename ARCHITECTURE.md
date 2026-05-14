# System Architecture: Amal Tracker Monorepo

This document outlines the technical design and architectural principles governing the Amal Tracker platform.

## Monorepo Strategy

The platform is engineered as a single-source monorepo to maintain high consistency across different user roles. By sharing the core domain logic, data models, and infrastructure services, we ensure that updates to the underlying system are reflected in all application targets simultaneously.

### Application Kernel (AppCore)
The system boots through a shared initialization kernel located in `lib/app_core.dart`. This class manages the parallel initialization of:
*   Timezone databases and local location detection.
*   Isar local database hydration.
*   Supabase cloud services and authentication state.
*   UI rendering pipeline pre-warming to reduce interface latency.

### Multi-Target Execution
The build system uses targeted entry points (`main_client.dart` and `main_admin.dart`) combined with Flutter Flavors to produce specialized binaries. This provides a hard boundary at the binary level for application identity and local storage.

## Security and Access Control

The system implements a defense-in-depth strategy for institutional security:

1.  Binary Identity: Unique Package IDs and signing configurations for each application target.
2.  Role Validation: Synchronous verification of user roles against the live database profile during the routing phase.
3.  Biometric Authentication: Mandatory hardware-backed authentication (`local_auth`) for administrative dashboard access.
4.  Data Isolation: Supabase Row Level Security (RLS) policies to ensure data privacy and institutional integrity.

## Data Persistence and Synchronization

The platform utilizes a local-first synchronization engine to ensure operational reliability in varying network environments.

### Local-First Persistence
Isar Database serves as the primary source of truth for the user interface, providing low-latency data access. Changes are recorded locally and queued for background synchronization.

### Synchronization Engine
The synchronization logic is built on an atomic batching system:
*   Batch Processing: Data is synchronized in manageable chunks to ensure network stability.
*   Conflict Resolution: A Last-Write-Wins (LWW) strategy is employed using nano-precision timestamps.
*   Reliability: Chunked upserts and structured result handling ensure data consistency across multiple devices.

## Design System

The user interface is governed by a semantic theme extension architecture. This allows the application to dynamically resolve aesthetic properties (such as colors and haptics) based on the spiritual context and time of day, while maintaining a consistent institutional brand identity.
