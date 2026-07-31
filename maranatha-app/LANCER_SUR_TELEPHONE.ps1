$ErrorActionPreference = "Stop"

Write-Host "Installation des dépendances Flutter..." -ForegroundColor Cyan
flutter pub get

Write-Host "Analyse du projet..." -ForegroundColor Cyan
flutter analyze

Write-Host "Lancement sur le TECNO KM4..." -ForegroundColor Green
flutter run -d 148467059C008509
