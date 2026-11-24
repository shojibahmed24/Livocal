# Production build with obfuscation and split debug symbols.
#
# Usage:
#   pwsh tool/build_release.ps1                 # App Bundle (Play Store)
#   pwsh tool/build_release.ps1 -Target apk     # APK for direct install
#
# Set the relay URL for the environment you are shipping:
#   -Stage prod|staging
param(
    [ValidateSet('aab', 'apk')]
    [string]$Target = 'aab',
    [ValidateSet('prod', 'staging')]
    [string]$Stage = 'prod'
)

$ErrorActionPreference = 'Stop'

$relay = if ($Stage -eq 'staging') {
    'https://livocal-relay-staging.onrender.com'
} else {
    'https://livocal-relay.onrender.com'
}

Write-Host "Building $Target for $Stage (relay: $relay)"

$symbolsDir = "build/symbols/$Stage"
New-Item -ItemType Directory -Force -Path $symbolsDir | Out-Null

$common = @(
    '--release',
    '--obfuscate',
    "--split-debug-info=$symbolsDir",
    "--dart-define=RELAY_URL=$relay"
)

if ($Target -eq 'aab') {
    flutter build appbundle @common
    Write-Host "AAB: build/app/outputs/bundle/release/app-release.aab"
} else {
    flutter build apk @common
    Write-Host "APK: build/app/outputs/flutter-apk/app-release.apk"
}

Write-Host @"

Symbols: $symbolsDir
Keep this folder private. To de-obfuscate a Crashlytics stack trace:

  flutter symbolize -i <stacktrace.txt> -d $symbolsDir/app.android-arm64.symbols

Reminders:
  - android/key.properties + upload keystore must exist for a release build.
  - Play App Signing must be enabled before the first upload.
"@
