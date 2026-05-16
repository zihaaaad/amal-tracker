# Institutional Operations Manual: Amal Tracker

This document provides operational guidance for the deployment and management of the Amal Tracker platform.

## System Components

The platform consists of two specialized applications sharing a common backend infrastructure:
1.  Amal Tracker (Client): Daily practice tracking for foundation employees.
2.  Foundation Admin: Institutional oversight and analytics for management.

## Operational Procedures

### Application Initialization
Both applications utilize the `AppCore` initialization kernel. This ensures that environmental variables, timezone detection, and local database hydration are performed consistently before the user interface is presented.

### Environment Management
The platform uses build flavors to manage application identity. This allows both the Client and Admin versions to coexist on the same device without data or preference conflicts.

| Application Target | Execution Command | Production Build Command |
| :--- | :--- | :--- |
| Client | `flutter run --flavor client -t lib/main_client.dart` | `flutter build apk --release --flavor client -t lib/main_client.dart` |
| Admin | `flutter run --flavor admin -t lib/main_admin.dart` | `flutter build apk --release --flavor admin -t lib/main_admin.dart` |

## Security & Access Control

### Role-Based Access (RBAC)
User roles are managed in the Supabase `profiles` table.
-   **Role: 'employee'** - Can only access the Client app.
-   **Role: 'admin'** - Can access both apps. Access to the Admin app is further gated by a mandatory biometric challenge.

### Supabase Dashboard Configuration (CRITICAL)
To ensure Google Login and Deep Linking work correctly, you MUST configure your Supabase Dashboard:

1.  **Allowed Redirect URLs**:
    -   Go to **Authentication** -> **URL Configuration**.
    -   Add `com.amaltracker.auth://callback`
    -   Add `com.amaltracker.admin.auth://callback`
    -   *Note:* Ensure there are no trailing slashes unless explicitly used in the code.

2.  **External Providers**:
    -   Go to **Authentication** -> **Providers** -> **Google**.
    -   Ensure it is enabled and configured with your Google Client ID and Secret.
    -   Enable **Skip nonce check** for standard OAuth flow if necessary.

### Institutional Protection
The system uses **Dynamic Auth Redirects**. The Client app redirects to `com.amaltracker.auth`, while the Admin app uses `com.amaltracker.admin.auth`. This prevents cross-app authentication leaks.

## Data Oversight and Reporting

The administrative dashboard provides institutional-level metrics, including participation rates and performance analytics. These metrics are calculated via the `AdminService` by aggregating historical log data and profile metadata.

## Continuous Delivery

The deployment pipeline is automated through GitHub Actions. Each commit to the primary branch initiates an automated build of both APK targets, ensuring that the latest institutional updates are always available for distribution.
