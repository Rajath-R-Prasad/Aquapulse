class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://euwztttrbiwwuopfdfqh.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1d3p0dHRyYml3d3VvcGZkZnFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI0MTA5NTksImV4cCI6MjEwNzk4Njk1OX0.JGD3ZKmSSCPWGMNBhOuHVk32L9PVpsseLPqzl5o6MsE',
  );

  static const bool enableFirebaseMessaging = bool.fromEnvironment(
    'ENABLE_FIREBASE_MESSAGING',
    defaultValue: false,
  );

  static const double mapCenterLat = 12.2958;
  static const double mapCenterLon = 76.6394;
  static const int mapZoom = 17;
}
