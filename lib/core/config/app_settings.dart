bool _parseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  final str = value.toString().toLowerCase().trim();
  return str == '1' || str == 'true' || str == 'yes' || str == 'on';
}

class AppSettings {
  final String appTitle;
  final String primaryColorHex;
  final String tgBotUsername;
  final bool requireAccessCode;
  final String flexColorScheme;

  AppSettings({
    required this.appTitle,
    required this.primaryColorHex,
    required this.tgBotUsername,
    required this.requireAccessCode,
    required this.flexColorScheme,
  });

  /// Creates AppSettings from the raw API/cache map.
  factory AppSettings.fromMap(Map<String, dynamic> data) {
    return AppSettings(
      appTitle: data['app_title'] ?? 'Student Quiz',
      primaryColorHex: data['primary_color'] ?? '#673AB7',
      tgBotUsername: data['tg_bot_username'] ?? '',
      requireAccessCode: _parseBool(data['require_access_code'], defaultValue: false),
      flexColorScheme: data['flex_color_scheme'] ?? 'blueWhale',
    );
  }

  factory AppSettings.defaultSettings() {
    return AppSettings(
      appTitle: 'Student Quiz',
      primaryColorHex: '#673AB7',
      tgBotUsername: '',
      requireAccessCode: false,
      flexColorScheme: 'blueWhale',
    );
  }
}
