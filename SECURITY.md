# Security Architecture: Amal Tracker Monorepo

This document outlines the security protocols and compliance measures implemented to protect institutional data and employee privacy.

## 🛡️ Defense-in-Depth Strategy

### 1. Identity & Access Management (IAM)
- **Role-Based Access Control (RBAC)**: Enforced via Supabase `profiles`. 
  - `employee`: Access restricted to personal tracking targets.
  - `admin`/`manager`: Full institutional dashboard access.
- **Hard Boundary Routing**: The application kernel (`_AppRouter`) performs a synchronous server-side role check before granting entry to administrative binaries.
- **Biometric Hardware Gating**: Access to the Admin Dashboard requires a hardware-backed biometric challenge (`local_auth`) for every session.

### 2. Data Protection
- **Encryption in Transit**: All communications with Supabase and Firebase are secured via TLS 1.3.
- **Encryption at Rest**: Local data stored in Isar is isolated at the OS level per binary flavor (`com.amaltracker.app` vs `com.amaltracker.admin`).
- **Row Level Security (RLS)**: Enforced at the PostgreSQL level. Users can only perform `SELECT`, `INSERT`, or `UPDATE` on records where `auth.uid() = user_id`.

### 3. API Key Management
- **Environment Isolation**: Production keys are never stored in the source code.
- **CI/CD Secrets**: All signing keys and Supabase credentials are managed via GitHub Actions Secrets.
- **Leak Protection**: `.gitignore` is configured to prevent accidental commits of `.env` or sensitive configuration files.

## 📝 Audit Logging
All administrative changes (Task modifications, Role updates) are timestamped and linked to the unique `auth.uid()` of the administrator. This ensures accountability for institutional modifications.

## 🛡️ Vulnerability Reporting
If you identify a security defect, please refer to our [CONTRIBUTING.md](CONTRIBUTING.md) for the disclosure process. Do not open public issues for security vulnerabilities.

---
**Institutional Integrity. Engineering Excellence.**
