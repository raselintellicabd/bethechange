import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_flavor.dart';

class EnvConfig {
  EnvConfig._();

  static late AppFlavor flavor;

  static Future<void> load(AppFlavor appFlavor) async {
    flavor = appFlavor;
    await dotenv.load(fileName: appFlavor.envFileName);
  }

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api-dev.example.com';

  static String get chatbotApiKey =>
      dotenv.env['CHATBOT_API_KEY'] ?? 'placeholder';

  static String get appName => dotenv.env['APP_NAME'] ?? 'BeTheChange';

  /// When true, [ApiClient] serves local JSON via [MockApiInterceptor].
  /// Defaults to true until the Django REST API is ready.
  static bool get useMockApi {
    final raw = dotenv.env['USE_MOCK_API']?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return true;
    return raw == 'true' || raw == '1' || raw == 'yes';
  }
}
