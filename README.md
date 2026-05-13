# 🕌 Amal Tracker - Institutional Edition

[![Flutter](https://img.shields.io/badge/Flutter-3.11.5-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Isar](https://img.shields.io/badge/Isar-NoSQL-4285F4)](https://isar.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An elite, high-performance daily practice tracker built specifically for institutional use at the **As-Sunnah Foundation**. This platform enables employees to monitor their spiritual growth while providing administrators with high-level data insights into organizational well-being.

---

## 💎 Premium Features

- **🛡️ Enterprise Security:** Biometric-gated Admin Panel (`local_auth`) with hardware-backed security.
- **⚡ Offline-First Architecture:** Powered by **Isar Database** for 0ms latency local reads.
- **☁️ Professional Sync:** Advanced conflict resolution logic (Last-Write-Wins) using Supabase.
- **📊 Deep Analytics:** Dynamic charts for streak tracking, completion rates, and historical growth.
- **🎨 Elite UI/UX:** A bespoke design system utilizing custom theme extensions, glassmorphism, and haptic-driven interactions.

---

## 🏗️ Technical Architecture

The project follows a **Feature-First Domain-Driven Design (DDD)** approach, ensuring scalability and maintainability.

```text
lib/
├── core/               # Shared logic, services, and themes
│   ├── constants/      # App-wide constants
│   ├── database/       # Isar schemas and initialization
│   ├── services/       # Core singletons (Auth, Notifications, etc.)
│   └── theme/          # Bespoke design system and color tokens
├── features/           # Independent business modules
│   ├── admin/          # Institutional management & oversight
│   ├── analytics/      # Historical data processing & visualization
│   ├── auth/           # Identity & institutional onboarding
│   ├── settings/       # User preferences & cloud management
│   └── tracker/        # Core daily tracking & log management
└── shared/             # Reusable UI components & models
```

---

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK `^3.11.5`
- A Supabase Project with our custom SQL schema applied.

### Local Setup
1. **Clone the repository:**
   ```bash
   git clone https://github.com/zihaaaad/amal-tracker.git
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Generate local database schemas:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. **Configure environment:**
   Update `lib/core/constants/app_constants.dart` with your Supabase credentials.

---

## 🚢 Deployment & CI/CD
We utilize a hardened **GitHub Actions** workflow for production delivery:
- **Analyze:** Strict linting and analysis rules.
- **Build:** Automated release APK generation.
- **Release:** Continuous Deployment to GitHub Releases.

---

## 🤝 Contributing
As an enterprise application, we maintain high standards for code quality. Please refer to [CONTRIBUTING.md](CONTRIBUTING.md) for our architectural guidelines and PR process.

---

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Engineered with precision for the As-Sunnah Foundation.**
