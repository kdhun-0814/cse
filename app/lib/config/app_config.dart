class AppConfig {
  // Method A: --dart-define (Compile-time variables)
  // Usage: flutter run --dart-define=GEMINI_API_KEY=your_actual_key

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Default to empty if not found (Secure)
  );

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
