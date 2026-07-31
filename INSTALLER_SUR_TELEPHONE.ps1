param(
    [string]$DeviceId = "148467059C008509"
)

$ErrorActionPreference = "Stop"
$app = Join-Path $PSScriptRoot "maranatha-app"

if (!(Test-Path (Join-Path $app "pubspec.yaml"))) {
    Write-Host "Projet Flutter introuvable : $app" -ForegroundColor Red
    exit 1
}

Set-Location $app

flutter pub get
dart format .\lib
flutter analyze
flutter run -d $DeviceId
