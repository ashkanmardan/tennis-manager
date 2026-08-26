# sync_to_tennisapp.ps1
# Copies all new lib files + pubspec.yaml from workspace to C:\TennisApp

$src = "C:\Users\Ashkan\Claude\Projects\اپ اندروید"
$dst = "C:\TennisApp"

Write-Host "Syncing files from workspace to TennisApp..." -ForegroundColor Cyan

# Copy entire lib folder
Write-Host "  Copying lib/..." -ForegroundColor Yellow
Copy-Item -Path "$src\lib" -Destination "$dst\" -Recurse -Force

# Copy pubspec.yaml
Write-Host "  Copying pubspec.yaml..." -ForegroundColor Yellow
Copy-Item -Path "$src\pubspec.yaml" -Destination "$dst\pubspec.yaml" -Force

Write-Host ""
Write-Host "Done! Now run:" -ForegroundColor Green
Write-Host "  cd C:\TennisApp" -ForegroundColor White
Write-Host "  flutter pub get" -ForegroundColor White
Write-Host "  D:\flutter\bin\flutter.bat build apk --release" -ForegroundColor White
