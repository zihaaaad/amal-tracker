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

## Security Management

### Access Control
User access is governed by the `role` field within the institutional database profiles.
*   Standard employees are limited to the Client application.
*   Administrators are granted access to the Admin application, which requires secondary biometric authentication for every session.

### Authentication Protection
Unique authentication redirect schemes are employed to ensure that login callbacks are routed to the correct application target, preventing cross-application authentication leaks.

## Data Oversight and Reporting

The administrative dashboard provides institutional-level metrics, including participation rates and performance analytics. These metrics are calculated via the `AdminService` by aggregating historical log data and profile metadata.

## Continuous Delivery

The deployment pipeline is automated through GitHub Actions. Each commit to the primary branch initiates an automated build of both APK targets, ensuring that the latest institutional updates are always available for distribution.
