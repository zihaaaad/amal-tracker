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

2.  **External Providers (Google)**:
    -   Go to **Authentication** -> **Providers** -> **Google**.
    -   Ensure it is enabled and configured with your Google Client ID and Secret.
    -   **Skip nonce check**: Enable this for standard OAuth flows.

### Google Cloud Console Checklist
If the app returns to the login screen without showing a user in Supabase, check these in your [Google Cloud Console](https://console.cloud.google.com/):

1.  **Authorized Redirect URIs**:
    -   Find your Supabase Project URL (e.g., `https://xyz.supabase.co`).
    -   Add the callback URI: `https://xyz.supabase.co/auth/v1/callback`
2.  **Android Client ID**:
    -   Create an **Android Client ID**.
    -   **Package Name**: `com.amaltracker.app` (for Client) and `com.amaltracker.admin` (for Admin).
    -   **SHA-1 Fingerprint**: You MUST add your machine's SHA-1 fingerprint. 
    -   *Command to get SHA-1:* `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
3.  **Client ID Synchronization (CRITICAL)**: 
    -   In **Supabase Dashboard** -> **Auth** -> **Providers** -> **Google**:
    -   The **Client ID** and **Client Secret** MUST come from the **Web Application** credential in your Google Cloud Console.
    -   **DO NOT** put your Android Client ID here. Supabase needs the Web ID to act as the intermediary proxy for the handshake.
    -   Your **Android Client ID** is only used to register your SHA-1 and Package Name in Google Cloud to authorize the redirect back to the app.

### Institutional Protection
The system uses **Dynamic Auth Redirects**. The Client app redirects to `com.amaltracker.auth`, while the Admin app uses `com.amaltracker.admin.auth`. This prevents cross-app authentication leaks.

## Data Oversight and Reporting

The administrative dashboard provides institutional-level metrics, including participation rates and performance analytics. These metrics are calculated via the `AdminService` by aggregating historical log data and profile metadata.

## Continuous Delivery

The deployment pipeline is automated through GitHub Actions. Each commit to the primary branch initiates an automated build of both APK targets, ensuring that the latest institutional updates are always available for distribution.
