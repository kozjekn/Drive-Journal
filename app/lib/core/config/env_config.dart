import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
}
