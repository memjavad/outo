$files = Get-ChildItem -Path "c:\the ai\outo platfrom\lib\presentation\screens" -Recurse -File -Filter *.dart
foreach ($file in $files) {
    (Get-Content $file.FullName) | ForEach-Object { $_ -replace "'\.\./\.\./models/quiz_model.dart'", "'../../domain/entities/entities.dart'" } | Set-Content $file.FullName
}

$service = "c:\the ai\outo platfrom\lib\services\quiz_service.dart"
if (Test-Path $service) {
    (Get-Content $service) | ForEach-Object { $_ -replace "'\.\./models/quiz_model.dart'", "'../domain/entities/entities.dart'" } | Set-Content $service
}

$test = "c:\the ai\outo platfrom\test_fetch.dart"
if (Test-Path $test) {
    (Get-Content $test) | ForEach-Object { $_ -replace "'lib/models/quiz_model.dart'", "'lib/domain/entities/entities.dart'" } | Set-Content $test
}
