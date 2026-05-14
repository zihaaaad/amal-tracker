# Amal Tracker: Environment Setup Script
# This script initializes the development environment for the Amal Tracker Monorepo.

Write-Host "Initializing Amal Tracker Development Environment..." -ForegroundColor Cyan

# 1. Verify Flutter SDK
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "Verification: Flutter SDK identified." -ForegroundColor Green
} else {
    Write-Host "Error: Flutter SDK not identified. Please ensure Flutter is installed and in your PATH." -ForegroundColor Red
    exit
}

# 2. Synchronize Dependencies
Write-Host "Action: Synchronizing project dependencies..." -ForegroundColor Yellow
flutter pub get

# 3. Execute Build Runner
Write-Host "Action: Generating local database schemas..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs

Write-Host "Success: Environment initialization complete." -ForegroundColor Green
Write-Host "To execute the Client application: flutter run --flavor client -t lib/main_client.dart" -ForegroundColor Cyan
Write-Host "To execute the Admin application:  flutter run --flavor admin -t lib/main_admin.dart" -ForegroundColor Cyan
