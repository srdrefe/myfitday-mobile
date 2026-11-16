import 'dart:convert';

import 'package:http/http.dart' as http;

class AiService {
  // Android emülatörü bilgisayarın localhost'una 10.0.2.2 üzerinden bağlanır
  static const String baseUrl = 'http://10.0.2.2:3000/api/ai';

  static Future<String> askGemini(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mesaj': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['yanit'] ?? 'Yanıt alınamadı.';
      } else if (response.statusCode == 503) {
        return 'Sunucular şu an yoğun, lütfen biraz bekle ⏳';
      } else {
        return 'Bağlantı hatası: ${response.statusCode}';
      }
    } catch (e) {
      return 'Sunucuya ulaşılamadı. Backend açık mı?';
    }
  }
}
