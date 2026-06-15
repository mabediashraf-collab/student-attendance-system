import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String baseUrl = 'http://localhost/sms_api';
  
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_notifications.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['notifications'] != null) {
          return List<Map<String, dynamic>>.from(data['notifications']);
        }
      }
      return [];
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}
