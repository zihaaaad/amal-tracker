# Contributing to Amal Tracker

We welcome contributions that maintain our standard of excellence. As an institutional application, please adhere to the following guidelines.

## 🏗️ Architectural Principles

- **Clean Code:** Use meaningful names, short functions, and follow the DRY (Don't Repeat Yourself) principle.
- **Provider-Based State:** We use `flutter_riverpod` for all state management. Avoid using `setState` in complex widgets.
- **Service Pattern:** Database and API calls must be encapsulated in service classes (e.g., `DatabaseService`).
- **Themes:** Always use `context.timeTint`, `context.surface`, etc., from our `ThemeExtension`. Never hardcode colors in widgets.

## 🛠️ Development Workflow

1. **Branching:** Use descriptive branch names: `feature/xxx`, `bugfix/xxx`, or `chore/xxx`.
2. **Analysis:** Run `flutter analyze` before committing. We do not accept PRs with linting warnings.
3. **Commits:** Follow conventional commits (e.g., `feat:`, `fix:`, `docs:`, `style:`).

## 🧪 Testing

- Ensure all new features are tested locally against a Supabase environment.
- Verify that `build_runner` has been executed if you modified any Isar schemas.

## 🛡️ Security

- Never commit API keys or environment secrets.
- Ensure that any administrative features are protected by the `AdminDashboard` biometric gate.

Thank you for contributing to the growth of the As-Sunnah Foundation's digital tools.
