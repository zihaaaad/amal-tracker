# Amal Tracker - Environment Setup Script
# This script initializes the development environment for the Amal Tracker.

Write-Host "🕌 Initializing Amal Tracker Development Environment..." -ForegroundColor Cyan

# 1. Check for Flutter
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "✅ Flutter SDK found." -ForegroundColor Green
} else {
    Write-Host "❌ Flutter SDK not found. Please install Flutter before proceeding." -ForegroundColor Red
    exit
}

# 2. Install dependencies
Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
flutter pub get

# 3. Run Build Runner
Write-Host "⚙️ Generating Isar database schemas..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs

Write-Host "🚀 Environment setup complete! Run 'flutter run' to start the application." -ForegroundColor Green
