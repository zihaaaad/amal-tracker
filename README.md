# Amal Tracker

A premium, offline-first Islamic daily practices tracker built with Flutter, applying Clean Architecture and an automated CI/CD pipeline.

## 🌟 Overview

Amal Tracker is designed to help Muslims track their daily Salah, Masnoon Azkar, Sunnah habits, and weekly/monthly rituals. Instead of feeling like a tedious checklist, the app is crafted to feel like a high-end productivity tool with a "Zen" aesthetic. It features a Bento grid layout, swipe-to-complete actions with haptic feedback, hold-to-fill counters, and an intelligent context-aware dashboard that adapts to the time of day.

## 🚀 Key Features

- **Context-Aware Dashboard**: The home screen filters and highlights specific Amal (e.g., Fajr, Dhuhr, Evening Azkar) based on the current time of day, reducing cognitive load.
- **Premium Gestures & Haptics**: 
  - Swipe-to-complete cards with spring-back physics and satisfying visual reveals.
  - Hold-to-fill circular counters for Azkar and Sunnah prayers.
- **Offline-First Architecture**: Uses a local, SharedPreferences-backed data store ensuring the app is always fast and doesn't require an active internet connection.
- **Smart Background Logic**: Utilizes `WorkManager` for an on-device "AI-like" notification engine (e.g., Sleep reminders at 10:00 PM, Friday Kahf reminders, Streak alerts).
- **On-Device PDF Reports**: Converts your digital tracking data into a beautifully formatted, printable monthly PDF report using the `pdf` and `printing` packages.
- **Automated CI/CD**: A GitHub Actions workflow compiles the app and generates a release-ready APK artifact every time code is pushed to the `main` branch.

## 📐 Architecture & Standards

This project adheres strictly to international software engineering standards for scalable mobile applications:

1. **Feature-First Clean Architecture**:
   - `core/`: Contains app-wide services (database, notifications), constants, and theme definitions.
   - `features/`: The app is split into independent feature modules (`tracker`, `analytics`, `settings`, `pdf_report`). This ensures low coupling and high cohesion.
   - `shared/`: Houses reusable UI components (Glassmorphic cards, custom gestures) and extensions.
2. **State Management**:
   - Built heavily on **Riverpod**, the industry-standard reactive state management solution for Flutter, ensuring UI and business logic are cleanly separated.
3. **UI/UX Best Practices**:
   - Uses a centralized **Design System** (`AppColors`, `AppTypography`, `AppTheme`) to ensure consistency.
   - Adopts a visually appealing Glassmorphic dark mode design, reducing eye strain and providing a premium feel.
4. **SOLID Principles**:
   - Services like `DatabaseService` and `NotificationService` are isolated, making them easy to swap or test without affecting the UI.

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: flutter_riverpod
- **Local Database**: shared_preferences (with local JSON proxy caching)
- **Background Tasks**: workmanager
- **Notifications**: flutter_local_notifications
- **PDF Generation**: pdf & printing
- **Charts/Analytics**: fl_chart
- **CI/CD**: GitHub Actions

## 📱 CI/CD & Deployment

This project includes a fully configured `.github/workflows/build_release.yml` file. 

Whenever changes are pushed to the `main` branch:
1. GitHub Actions provisions an Ubuntu runner.
2. Sets up the Flutter SDK and Java environments.
3. Resolves dependencies.
4. Analyzes the code.
5. Builds a production-ready `app-release.apk`.
6. Uploads the APK as a downloadable artifact.

## 🏃 Getting Started

To run this project locally:

1. Clone the repository:
   ```bash
   git clone https://github.com/zihaaaad/amal-tracker.git
   ```
2. Navigate to the project directory:
   ```bash
   cd amal-tracker
   ```
3. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

*(Note: Supabase backend integration is currently scaffolded but disabled for the offline-first experience. To enable cloud sync, provide valid keys in `lib/core/constants/app_constants.dart`.)*
