# Contributing to Amal Tracker Monorepo

We maintain an elite standard for institutional software. Contributions must respect the **Single-Source Monorepo** architecture and follow strict engineering protocols.

## 🏗️ Monorepo Integrity

- **Shared Kernel:** Any changes to `lib/app_core.dart` or `lib/core/` affect **both** applications. Always test both the Client and Admin targets after modifying core infrastructure.
- **Feature Isolation:** Keep feature-specific logic within its folder in `lib/features/`. Use the `AppMode` enum if a shared widget needs to behave differently between apps.
- **Provider Pattern:** We use `flutter_riverpod` for all state management. State should be reactive and scoped appropriately.

## 🛠️ Professional Standards

- **Conventional Commits:** Use semantic commit messages (e.g., `feat(admin): add report exporting`, `fix(sync): resolve race condition`).
- **Targeted Testing:** Verify changes by running:
  - `flutter run --flavor client -t lib/main_client.dart`
  - `flutter run --flavor admin -t lib/main_admin.dart`
- **Zero-Warning Policy:** We do not accept PRs with `flutter analyze` warnings or infos. Run analysis locally before pushing.

## 🧪 Database & Schema

- **Isar:** If you modify a schema in `lib/core/database/isar_schemas.dart`, you **must** run `dart run build_runner build` and include the generated `.g.dart` files in your commit.
- **Supabase:** Ensure migrations are added to the `supabase/migrations/` folder for any schema changes.

## 🛡️ Security Gatekeeping

- **Never** expose API keys or credentials.
- Any new administrative functionality **must** be protected by the biometric gate in the `AdminDashboardScreen`.
- Ensure Row Level Security (RLS) is considered for all new database tables.

---

**Built with excellence. Developed for impact.**
