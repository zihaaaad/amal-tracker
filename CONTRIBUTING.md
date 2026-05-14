# Contributing Guidelines: Amal Tracker Monorepo

Contributions to the Amal Tracker platform must adhere to the established architectural standards and institutional requirements.

## Engineering Principles

### Monorepo Integrity
*   Shared Infrastructure: Modifications to `lib/core/` or `lib/app_core.dart` impact all application targets. Developers must verify changes across both Client and Admin environments.
*   Feature Isolation: New business logic should be contained within modular directories in `lib/features/`.

### Development Standards
*   State Management: Riverpod is the mandatory state management solution. Logic should be reactive and decoupled from the presentation layer.
*   Data Persistence: Changes to database schemas in `lib/core/database/isar_schemas.dart` require a re-run of the code generation tool (`build_runner`).
*   Code Quality: Adherence to the project's strict analysis rules is mandatory. Use `flutter analyze` to verify compliance.

## Workflow

1.  Branching Strategy: Utilize descriptive branch prefixes (`feature/`, `bugfix/`, `chore/`).
2.  Commit Protocol: Follow conventional commit standards for clear version history.
3.  Verification: Ensure both application targets are buildable and functional:
    *   Client build: `flutter build apk --flavor client -t lib/main_client.dart`
    *   Admin build: `flutter build apk --flavor admin -t lib/main_admin.dart`

## Security Requirements

*   Sensitive Information: Do not commit API keys, service accounts, or environmental secrets.
*   Access Control: New administrative functionality must be integrated with the existing biometric security gate and RBAC logic.
*   Data Privacy: Respect Supabase Row Level Security (RLS) policies for all data access patterns.
