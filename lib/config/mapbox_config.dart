abstract final class MapboxConfig {
  static const accessToken = String.fromEnvironment('ACCESS_TOKEN');

  // Only public Mapbox tokens belong in a mobile build.
  static bool get isConfigured => accessToken.startsWith('pk.');
}
