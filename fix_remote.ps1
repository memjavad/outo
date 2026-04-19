$files = Get-ChildItem -Path "c:\the ai\outo platfrom\lib\data\sources\remote" -File -Filter *.dart
foreach ($file in $files) {
    (Get-Content $file.FullName) | 
        ForEach-Object { $_ -replace "'\.\./\.\./models/quiz_model.dart'", "'../../../domain/entities/entities.dart'" } |
        ForEach-Object { $_ -replace "'\.\./\.\./services/app_config.dart'", "'../../../core/config/app_config.dart'" } |
        Set-Content $file.FullName
}
