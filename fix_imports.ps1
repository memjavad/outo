$files = Get-ChildItem -Path "c:\the ai\outo platfrom\lib\presentation\screens" -Recurse -File -Filter *.dart
foreach ($file in $files) {
    (Get-Content $file.FullName) | 
        ForEach-Object { $_ -replace "'\.\./models/", "'../../models/" } |
        ForEach-Object { $_ -replace "'\.\./l10n/", "'../../l10n/" } |
        ForEach-Object { $_ -replace "'\.\./services/app_config.dart'", "'../../core/config/app_config.dart'" } |
        ForEach-Object { $_ -replace "'\.\./services/platform_utils.dart'", "'../../core/utils/platform_utils.dart'" } |
        ForEach-Object { $_ -replace "'\.\./services/language_provider.dart'", "'../../core/localization/language_provider.dart'" } |
        ForEach-Object { $_ -replace "'\.\./services/theme_provider.dart'", "'../../core/theme/theme_provider.dart'" } |
        ForEach-Object { $_ -replace "'\.\./services/quiz_service.dart'", "'../../services/quiz_service.dart'" } |
        Set-Content $file.FullName
}

$service = "c:\the ai\outo platfrom\lib\services\quiz_service.dart"
(Get-Content $service) | 
    ForEach-Object { $_ -replace "'app_config.dart'", "'../core/config/app_config.dart'" } |
    ForEach-Object { $_ -replace "'platform_utils.dart'", "'../core/utils/platform_utils.dart'" } |
    Set-Content $service

$test = "c:\the ai\outo platfrom\test_fetch.dart"
if (Test-Path $test) {
    (Get-Content $test) | ForEach-Object { $_ -replace "'lib/services/app_config.dart'", "'lib/core/config/app_config.dart'" } | Set-Content $test
}
