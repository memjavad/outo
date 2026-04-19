$files = Get-ChildItem -Path "c:\the ai\outo platfrom\lib\presentation\screens" -Recurse -File -Filter *.dart
foreach ($file in $files) {
    (Get-Content $file.FullName) | ForEach-Object { $_ -replace "'\.\./\.\./services/quiz_service.dart'", "'../providers/quiz_service_facade.dart'" } | Set-Content $file.FullName
}
if (Test-Path "c:\the ai\outo platfrom\lib\services") {
    Remove-Item -Path "c:\the ai\outo platfrom\lib\services" -Force -Recurse
}
