class AppConfig {
  AppConfig._();
  static const _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://gestio-stock-web.onrender.com/api/v1/',
  );

  static Uri get apiBaseUri {
    final uri = Uri.parse(
      _rawBaseUrl.endsWith('/') ? _rawBaseUrl : '$_rawBaseUrl/',
    );
    if (uri.scheme != 'https' && !isLocalDevelopment(uri)) {
      throw StateError(
        'API_BASE_URL doit utiliser HTTPS hors développement local.',
      );
    }
    return uri;
  }

  static bool isLocalDevelopment(Uri uri) =>
      uri.host == 'localhost' ||
      uri.host == '127.0.0.1' ||
      uri.host == '10.0.2.2';
  static String get environmentLabel {
    final uri = apiBaseUri;
    if (isLocalDevelopment(uri)) return 'DEV';
    if (uri.host.toLowerCase().contains('staging')) return 'STAGING';
    return 'PROD';
  }

  static const connectTimeout = Duration(seconds: 15);
  static const sendTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 25);
}
