// Autor: Wilbert López Veras
// Fecha de creación: 8 de Noviembre de 2025
// Descripción: Configuración de la API, incluyendo la URL base.
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    final isLoaded = dotenv.isInitialized;
    if (isLoaded) {
      final envValue = dotenv.env['API_BASE_URL'];
      if (envValue != null && envValue.isNotEmpty) {
        return envValue;
      }
    }
    return 'https://petconnect-ffhv.onrender.com';
  }
}
