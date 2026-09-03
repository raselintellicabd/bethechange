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
}
