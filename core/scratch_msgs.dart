// lib/engine/scratch_msgs.dart
class ScratchMsgs {
  // Singleton instance
  static final ScratchMsgs _instance = ScratchMsgs._internal();
  factory ScratchMsgs() => _instance;
  ScratchMsgs._internal();

  /// All locale messages
  final Map<String, Map<String, String>> locales = {};

  /// Current locale, default to English
  String _currentLocale = 'en';

  /// Set the current locale and apply it
  void setLocale(String locale) {
    if (locales.containsKey(locale)) {
      _currentLocale = locale;
    } else {
      print('Ignoring unrecognized locale: $locale');
    }
  }

  /// Get a translated message
  /// [msgId] is the key, [defaultMsg] fallback, [useLocale] optional override
  String translate(String msgId, String defaultMsg, [String? useLocale]) {
    final locale = useLocale ?? _currentLocale;
    if (locales.containsKey(locale)) {
      final messages = locales[locale]!;
      if (messages.containsKey(msgId)) {
        return messages[msgId]!;
      }
    }
    return defaultMsg;
  }

  /// Load messages for a specific locale
  void addLocale(String locale, Map<String, String> messages) {
    locales[locale] = messages;
  }

  /// Get current locale
  String get currentLocale => _currentLocale;
}
